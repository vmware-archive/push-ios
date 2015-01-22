//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "PCFPushClient.h"
#import "PCFPushDebug.h"
#import "PCFPushErrors.h"
#import "PCFPushParameters.h"
#import "PCFNotifications.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushURLConnection.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushRegistrationResponseData.h"

typedef void (^RegistrationBlock)(NSURLResponse *response, id responseData);

static PCFPushClient *_sharedPCFPushClient;
static dispatch_once_t _sharedPCFPushClientToken;

@implementation PCFPushClient

+ (instancetype)shared
{
    dispatch_once(&_sharedPCFPushClientToken, ^{
        if (!_sharedPCFPushClient) {
            _sharedPCFPushClient = [[PCFPushClient alloc] init];
        }
    });
    return _sharedPCFPushClient;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.registrationParameters = [PCFPushParameters defaultParameters];
    }
    return self;
}

- (void)registerWithPCFPushWithDeviceToken:(NSData *)deviceToken
                                   success:(void (^)(void))successBlock
                                   failure:(void (^)(NSError *))failureBlock
{
    if (!self.registrationParameters) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters may not be nil."];
    }

    if (![self.registrationParameters arePushParametersValid]) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters are not valid. See log for more info."];
    }

    if (!deviceToken) {
        [NSException raise:NSInvalidArgumentException format:@"Device Token cannot not be nil."];
    }
    if (![deviceToken isKindOfClass:[NSData class]]) {
        [NSException raise:NSInvalidArgumentException format:@"Device Token type does not match expected type. NSData."];
    }

    if ([PCFPushClient updateRegistrationRequiredForDeviceToken:deviceToken parameters:self.registrationParameters]) {
        RegistrationBlock registrationBlock = [PCFPushClient registrationBlockWithParameters:self.registrationParameters
                                                                                 deviceToken:deviceToken
                                                                                     success:successBlock
                                                                                     failure:failureBlock];

        [PCFPushURLConnection updateRegistrationWithDeviceID:[PCFPushPersistentStorage serverDeviceID]
                                                  parameters:self.registrationParameters
                                                 deviceToken:deviceToken
                                                     success:registrationBlock
                                                     failure:failureBlock];

    } else if ([PCFPushClient registrationRequiredForDeviceToken:deviceToken parameters:self.registrationParameters]) {
        [PCFPushClient sendRegisterRequestWithParameters:self.registrationParameters
                                             deviceToken:deviceToken
                                                 success:successBlock
                                                 failure:failureBlock];

    } else {
        PCFPushLog(@"Registration with PCF Push is being bypassed (already registered).");
        if (successBlock) {
            successBlock();
        }
    }
}

- (void)unregisterForRemoteNotificationsWithSuccess:(void (^)(void))success
                                            failure:(void (^)(NSError *error))failure
{
    NSString *deviceId = [PCFPushPersistentStorage serverDeviceID];
    if (!deviceId || deviceId.length <= 0) {
        PCFPushLog(@"Not currently registered.");
        [self handleUnregistrationSuccess:success userInfo:@{ @"Response": @"Already unregistered."}];
        return;
    }
    
    [PCFPushURLConnection unregisterDeviceID:deviceId
                                  parameters:self.registrationParameters
                                     success:^(NSURLResponse *response, NSData *data) {

                                         [self handleUnregistrationSuccess:success userInfo:@{@"URLResponse" : response}];
                                     }
                                     failure:failure];
}

- (void) handleUnregistrationSuccess:(void (^)(void))success userInfo:(NSDictionary*)userInfo
{
    [PCFPushPersistentStorage reset];
    
    if (success) {
        success();
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:PCFPushUnregisterNotification object:self userInfo:userInfo];
}

+ (RegistrationBlock)registrationBlockWithParameters:(PCFPushParameters *)parameters
                                         deviceToken:(NSData *)deviceToken
                                             success:(void (^)(void))successBlock
                                             failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = ^(NSURLResponse *response, id responseData) {
        NSError *error;
        
        if (!responseData || ([responseData isKindOfClass:[NSData class]] && [(NSData *)responseData length] <= 0)) {
            error = [PCFPushErrorUtil errorWithCode:PCFPushBackEndRegistrationEmptyResponseData localizedDescription:@"Response body is empty when attempting registration with back-end server"];
            PCFPushLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        PCFPushRegistrationResponseData *parsedData = [PCFPushRegistrationResponseData pcf_fromJSONData:responseData error:&error];
        
        if (error) {
            PCFPushLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        if (!parsedData.deviceUUID) {
            error = [PCFPushErrorUtil errorWithCode:PCFPushBackEndRegistrationResponseDataNoDeviceUuid localizedDescription:@"Response body from registering with the back-end server does not contain an UUID "];
            PCFPushLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        PCFPushLog(@"Registration with back-end succeded. Device ID: \"%@\".", parsedData.deviceUUID);
        [PCFPushPersistentStorage setAPNSDeviceToken:deviceToken];
        [PCFPushPersistentStorage setServerDeviceID:parsedData.deviceUUID];
        [PCFPushPersistentStorage setVariantUUID:parameters.variantUUID];
        [PCFPushPersistentStorage setVariantSecret:parameters.variantSecret];
        [PCFPushPersistentStorage setDeviceAlias:parameters.pushDeviceAlias];
        [PCFPushPersistentStorage setTags:parameters.pushTags];
        
        if (successBlock) {
            successBlock();
        }
        
        NSDictionary *userInfo = @{ @"URLResponse" : response };
        [[NSNotificationCenter defaultCenter] postNotificationName:PCFPushRegistrationSuccessNotification object:self userInfo:userInfo];
    };
    
    return registrationBlock;
}

- (void) subscribeToTags:(NSSet *)tags deviceToken:(NSData *)deviceToken deviceUuid:(NSString *)deviceUuid success:(void (^)(void))success failure:(void (^)(NSError*))failure
{
    self.registrationParameters.pushTags = tags;

    // No tags are updated
    if ([PCFPushClient areTagsTheSame:self.registrationParameters]) {
        if (success) {
            success();
        }
        return;
    }

    RegistrationBlock registrationBlock = [PCFPushClient registrationBlockWithParameters:self.registrationParameters
                                                                             deviceToken:deviceToken
                                                                                 success:success
                                                                                 failure:failure];

    [PCFPushURLConnection updateRegistrationWithDeviceID:deviceUuid
                                              parameters:self.registrationParameters
                                             deviceToken:deviceToken
                                                 success:registrationBlock
                                                 failure:failure];
}

+ (void)sendRegisterRequestWithParameters:(PCFPushParameters *)parameters
                              deviceToken:(NSData *)deviceToken
                                  success:(void (^)(void))successBlock
                                  failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = [PCFPushClient registrationBlockWithParameters:parameters
                                                                             deviceToken:deviceToken
                                                                                 success:successBlock
                                                                                 failure:failureBlock];
    [PCFPushURLConnection registerWithParameters:parameters
                                     deviceToken:deviceToken
                                         success:registrationBlock
                                         failure:failureBlock];
}

+ (BOOL)updateRegistrationRequiredForDeviceToken:(NSData *)deviceToken
                                      parameters:(PCFPushParameters *)parameters
{
    // If not currently registered with the back-end then update registration is not required
    if (![PCFPushPersistentStorage APNSDeviceToken]) {
        return NO;
    }
    
    if (![PCFPushClient localDeviceTokenMatchesNewToken:deviceToken]) {
        return YES;
    }
    
    if (![PCFPushClient localParametersMatchNewParameters:parameters]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)registrationRequiredForDeviceToken:(NSData *)deviceToken
                                parameters:(PCFPushParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if (![PCFPushPersistentStorage serverDeviceID]) {
        return YES;
    }
    
    if (![PCFPushClient localDeviceTokenMatchesNewToken:deviceToken]) {
        return YES;
    }
    
    if (![PCFPushClient localParametersMatchNewParameters:parameters]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)localParametersMatchNewParameters:(PCFPushParameters *)parameters
{
    // If any of the registration parameters are different then unregistration is required
    NSString *savedVariantUUID = [PCFPushPersistentStorage variantUUID];
    if ((parameters.variantUUID == nil && savedVariantUUID != nil) || (parameters.variantUUID != nil && ![parameters.variantUUID isEqualToString:savedVariantUUID])) {
        PCFPushLog(@"Parameters specify a different variantUUID. Unregistration and re-registration will be required.");
        return NO;
    }
    
    NSString *savedVariantSecret = [PCFPushPersistentStorage variantSecret];
    if ((parameters.variantSecret == nil && savedVariantSecret != nil) || (parameters.variantSecret != nil && ![parameters.variantSecret isEqualToString:savedVariantSecret])) {
        PCFPushLog(@"Parameters specify a different variantSecret. Unregistration and re-registration will be required.");
        return NO;
    }
    
    NSString *savedDeviceAlias = [PCFPushPersistentStorage deviceAlias];
    if ((parameters.pushDeviceAlias == nil && savedDeviceAlias != nil) || (parameters.pushDeviceAlias != nil && ![parameters.pushDeviceAlias isEqualToString:savedDeviceAlias])) {
        PCFPushLog(@"Parameters specify a different deviceAlias. Unregistration and re-registration will be required.");
        return NO;
    }
    
    return [PCFPushClient areTagsTheSame:parameters];
}

+ (BOOL)areTagsTheSame:(PCFPushParameters *)parameters {
    NSSet *savedTags = [PCFPushPersistentStorage tags];
    BOOL areSavedTagsNilOrEmpty = savedTags == nil || savedTags.count == 0;
    BOOL areNewTagsNilOrEmpty = parameters.pushTags == nil || parameters.pushTags.count == 0;
    if ((areNewTagsNilOrEmpty && !areSavedTagsNilOrEmpty) || (!areNewTagsNilOrEmpty && ![parameters.pushTags isEqualToSet:savedTags])) {
        PCFPushLog(@"Parameters specify a different set of tags. Update registration will be required.");
        return NO;
    }
    return YES;
}

+ (BOOL)localDeviceTokenMatchesNewToken:(NSData *)deviceToken {
    if (![deviceToken isEqualToData:[PCFPushPersistentStorage APNSDeviceToken]]) {
        PCFPushLog(@"APNS returned a different APNS token. Unregistration and re-registration will be required.");
        return NO;
    }
    return YES;
}

// Helpers - used in unit tests

- (void)resetInstance
{
    self.registrationParameters = nil;
}

+ (void)resetSharedClient
{
    if (_sharedPCFPushClient) {
        [_sharedPCFPushClient resetInstance];
    }

    _sharedPCFPushClientToken = 0;
    _sharedPCFPushClient = nil;
}

@end
