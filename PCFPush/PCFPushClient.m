//
//  PCFPushClient.m
//  
//
//  Created by DX123-XL on 2014-04-23.
//
//

#import <UIKit/UIKit.h>

#import "PCFPushClient.h"
#import "PCFParameters.h"
#import "PCFAppDelegate.h"
#import "PCFAppDelegateProxy.h"
#import "PCFPersistentStorage+Push.h"
#import "PCFPushURLConnection.h"
#import "NSObject+PCFJsonizable.h"
#import "PCFPushRegistrationResponseData.h"
#import "NSURLConnection+PCFBackEndConnection.h"
#import "PCFPushDebug.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushErrors.h"
#import "PCFNotifications.h"

@implementation PCFPushClient

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

- (PCFAppDelegate *)swapAppDelegate
{
    PCFAppDelegate *pushAppDelegate = [super swapAppDelegate];
    
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
    [PCFPushURLConnection unregisterDeviceID:[PCFPersistentStorage serverDeviceID]
                                  parameters:self.registrationParameters
                                     success:^(NSURLResponse *response, NSData *data) {
                                         [PCFPersistentStorage resetPushPersistedValues];
                                         
                                         if (success) {
                                             success();
                                         }
                                         
                                         NSDictionary *userInfo = @{ @"URLResponse" : response };
                                         [[NSNotificationCenter defaultCenter] postNotificationName:PCFPushUnregisterNotification object:self userInfo:userInfo];
                                     }
                                     failure:failure];
}

typedef void (^RegistrationBlock)(NSURLResponse *response, id responseData);

+ (RegistrationBlock)registrationBlockWithParameters:(PCFParameters *)parameters
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
        [PCFPersistentStorage setAPNSDeviceToken:deviceToken];
        [PCFPersistentStorage setServerDeviceID:parsedData.deviceUUID];
        [PCFPersistentStorage setVariantUUID:parameters.variantUUID];
        [PCFPersistentStorage setReleaseSecret:parameters.releaseSecret];
        [PCFPersistentStorage setDeviceAlias:parameters.pushDeviceAlias];
        
        if (successBlock) {
            successBlock();
        }
        
        NSDictionary *userInfo = @{ @"URLResponse" : response };
        [[NSNotificationCenter defaultCenter] postNotificationName:PCFPushRegistrationSuccessNotification object:self userInfo:userInfo];
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
        
        [PCFPushURLConnection updateRegistrationWithDeviceID:[PCFPersistentStorage serverDeviceID]
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

+ (void)sendRegisterRequestWithParameters:(PCFParameters *)parameters
                              deviceToken:(NSData *)deviceToken
                                  success:(void (^)(void))successBlock
                                  failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = [self registrationBlockWithParameters:parameters
                                                                    deviceToken:deviceToken
                                                                        success:successBlock
                                                                        failure:failureBlock];
    [PCFPushURLConnection registerWithParameters:parameters
                                    deviceToken:deviceToken
                                        success:registrationBlock
                                        failure:failureBlock];
}

+ (BOOL)updateRegistrationRequiredForDeviceToken:(NSData *)deviceToken
                                      parameters:(PCFParameters *)parameters
{
    // If not currently registered with the back-end then update registration is not required
    if (![PCFPersistentStorage APNSDeviceToken]) {
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
                                parameters:(PCFParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if (![PCFPersistentStorage serverDeviceID]) {
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

+ (BOOL)localParametersMatchNewParameters:(PCFParameters *)parameters
{
    // If any of the registration parameters are different then unregistration is required
    if (![parameters.variantUUID isEqualToString:[PCFPersistentStorage variantUUID]]) {
        PCFPushLog(@"Parameters specify a different variantUUID. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.releaseSecret isEqualToString:[PCFPersistentStorage releaseSecret]]) {
        PCFPushLog(@"Parameters specify a different releaseSecret. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.pushDeviceAlias isEqualToString:[PCFPersistentStorage deviceAlias]]) {
        PCFPushLog(@"Parameters specify a different deviceAlias. Unregistration and re-registration will be required.");
        return NO;
    }
    
    return YES;
}

+ (BOOL)localDeviceTokenMatchesNewToken:(NSData *)deviceToken {
    if (![deviceToken isEqualToData:[PCFPersistentStorage APNSDeviceToken]]) {
        PCFPushLog(@"APNS returned a different APNS token. Unregistration and re-registration will be required.");
        return NO;
    }
    return YES;
}

@end
