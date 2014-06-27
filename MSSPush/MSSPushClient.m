//
//  MSSPushClient.m
//  
//
//  Created by DX123-XL on 2014-04-23.
//
//

#import <UIKit/UIKit.h>

#import "MSSPushClient.h"
#import "MSSParameters.h"
#import "MSSAppDelegate.h"
#import "MSSAppDelegateProxy.h"
#import "MSSPersistentStorage+Push.h"
#import "MSSPushURLConnection.h"
#import "NSObject+MSSJsonizable.h"
#import "MSSPushRegistrationResponseData.h"
#import "NSURLConnection+MSSBackEndConnection.h"
#import "MSSPushDebug.h"
#import "MSSPushErrorUtil.h"
#import "MSSPushErrors.h"
#import "MSSNotifications.h"

@implementation MSSPushClient

- (id)init
{
    self = [super init];
    if (self) {
        self.notificationTypes = (UIRemoteNotificationTypeAlert
                                  |UIRemoteNotificationTypeBadge
                                  |UIRemoteNotificationTypeSound);
    }
    return self;
}

- (MSSAppDelegate *)swapAppDelegate
{
    MSSAppDelegate *pushAppDelegate = [super swapAppDelegate];
    
    [pushAppDelegate setPushRegistrationBlockWithSuccess:^(NSData *deviceToken) {
        [self APNSRegistrationSuccess:deviceToken];
        
    } failure:^(NSError *error) {
        if (self.failureBlock) {
            self.failureBlock(error);
        }
    }];
    return pushAppDelegate;
}

- (void)registerForRemoteNotifications
{
    if (self.notificationTypes != UIRemoteNotificationTypeNone) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:self.notificationTypes];
    }
}

- (void)unregisterForRemoteNotificationsWithSuccess:(void (^)(void))success
                                            failure:(void (^)(NSError *error))failure
{
    [MSSPushURLConnection unregisterDeviceID:[MSSPersistentStorage serverDeviceID]
                                  parameters:self.registrationParameters
                                     success:^(NSURLResponse *response, NSData *data) {
                                         [MSSPersistentStorage resetPushPersistedValues];
                                         
                                         if (success) {
                                             success();
                                         }
                                         
                                         NSDictionary *userInfo = @{ @"URLResponse" : response };
                                         [[NSNotificationCenter defaultCenter] postNotificationName:MSSPushUnregisterNotification object:self userInfo:userInfo];
                                     }
                                     failure:failure];
}

typedef void (^RegistrationBlock)(NSURLResponse *response, id responseData);

+ (RegistrationBlock)registrationBlockWithParameters:(MSSParameters *)parameters
                                         deviceToken:(NSData *)deviceToken
                                             success:(void (^)(void))successBlock
                                             failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = ^(NSURLResponse *response, id responseData) {
        NSError *error;
        
        if (!responseData || ([responseData isKindOfClass:[NSData class]] && [(NSData *)responseData length] <= 0)) {
            error = [MSSPushErrorUtil errorWithCode:MSSPushBackEndRegistrationEmptyResponseData localizedDescription:@"Response body is empty when attempting registration with back-end server"];
            MSSPushLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        MSSPushRegistrationResponseData *parsedData = [MSSPushRegistrationResponseData mss_fromJSONData:responseData error:&error];
        
        if (error) {
            MSSPushLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        if (!parsedData.deviceUUID) {
            error = [MSSPushErrorUtil errorWithCode:MSSPushBackEndRegistrationResponseDataNoDeviceUuid localizedDescription:@"Response body from registering with the back-end server does not contain an UUID "];
            MSSPushLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        MSSPushLog(@"Registration with back-end succeded. Device ID: \"%@\".", parsedData.deviceUUID);
        [MSSPersistentStorage setAPNSDeviceToken:deviceToken];
        [MSSPersistentStorage setServerDeviceID:parsedData.deviceUUID];
        [MSSPersistentStorage setVariantUUID:parameters.variantUUID];
        [MSSPersistentStorage setReleaseSecret:parameters.releaseSecret];
        [MSSPersistentStorage setDeviceAlias:parameters.pushDeviceAlias];
        
        if (successBlock) {
            successBlock();
        }
        
        NSDictionary *userInfo = @{ @"URLResponse" : response };
        [[NSNotificationCenter defaultCenter] postNotificationName:MSSPushRegistrationSuccessNotification object:self userInfo:userInfo];
    };
    
    return registrationBlock;
}

- (void)APNSRegistrationSuccess:(NSData *)deviceToken
{
    if (!deviceToken) {
        [NSException raise:NSInvalidArgumentException format:@"Device Token cannot not be nil."];
    }
    if (![deviceToken isKindOfClass:[NSData class]]) {
        [NSException raise:NSInvalidArgumentException format:@"Device Token type does not match expected type. NSData."];
    }
    
    if ([self.class updateRegistrationRequiredForDeviceToken:deviceToken parameters:self.registrationParameters]) {
        RegistrationBlock registrationBlock = [self.class registrationBlockWithParameters:self.registrationParameters
                                                                              deviceToken:deviceToken
                                                                                  success:self.successBlock
                                                                                  failure:self.failureBlock];
        
        [MSSPushURLConnection updateRegistrationWithDeviceID:[MSSPersistentStorage serverDeviceID]
                                                  parameters:self.registrationParameters
                                                 deviceToken:deviceToken
                                                     success:registrationBlock
                                                     failure:self.failureBlock];
        
    } else if ([self.class registrationRequiredForDeviceToken:deviceToken parameters:self.registrationParameters]) {
        [self.class sendRegisterRequestWithParameters:self.registrationParameters
                                          deviceToken:deviceToken
                                              success:self.successBlock
                                              failure:self.failureBlock];
        
    } else if (self.successBlock) {
        self.successBlock();
    }
}

+ (void)sendRegisterRequestWithParameters:(MSSParameters *)parameters
                              deviceToken:(NSData *)deviceToken
                                  success:(void (^)(void))successBlock
                                  failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = [self registrationBlockWithParameters:parameters
                                                                    deviceToken:deviceToken
                                                                        success:successBlock
                                                                        failure:failureBlock];
    [MSSPushURLConnection registerWithParameters:parameters
                                    deviceToken:deviceToken
                                        success:registrationBlock
                                        failure:failureBlock];
}

+ (BOOL)updateRegistrationRequiredForDeviceToken:(NSData *)deviceToken
                                      parameters:(MSSParameters *)parameters
{
    // If not currently registered with the back-end then update registration is not required
    if (![MSSPersistentStorage APNSDeviceToken]) {
        return NO;
    }
    
    if (![self localDeviceTokenMatchesNewToken:deviceToken]) {
        return YES;
    }
    
    if (![self localParametersMatchNewParameters:parameters]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)registrationRequiredForDeviceToken:(NSData *)deviceToken
                                parameters:(MSSParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if (![MSSPersistentStorage serverDeviceID]) {
        return YES;
    }
    
    if (![self localDeviceTokenMatchesNewToken:deviceToken]) {
        return YES;
    }
    
    if (![self localParametersMatchNewParameters:parameters]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)localParametersMatchNewParameters:(MSSParameters *)parameters
{
    // If any of the registration parameters are different then unregistration is required
    if (![parameters.variantUUID isEqualToString:[MSSPersistentStorage variantUUID]]) {
        MSSPushLog(@"Parameters specify a different variantUUID. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.releaseSecret isEqualToString:[MSSPersistentStorage releaseSecret]]) {
        MSSPushLog(@"Parameters specify a different releaseSecret. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.pushDeviceAlias isEqualToString:[MSSPersistentStorage deviceAlias]]) {
        MSSPushLog(@"Parameters specify a different deviceAlias. Unregistration and re-registration will be required.");
        return NO;
    }
    
    return YES;
}

+ (BOOL)localDeviceTokenMatchesNewToken:(NSData *)deviceToken {
    if (![deviceToken isEqualToData:[MSSPersistentStorage APNSDeviceToken]]) {
        MSSPushLog(@"APNS returned a different APNS token. Unregistration and re-registration will be required.");
        return NO;
    }
    return YES;
}

@end
