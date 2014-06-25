//
//  PMSSPushClient.m
//  
//
//  Created by DX123-XL on 2014-04-23.
//
//

#import <UIKit/UIKit.h>

#import "PMSSPushClient.h"
#import "PMSSParameters.h"
#import "PMSSAppDelegate.h"
#import "PMSSAppDelegateProxy.h"
#import "PMSSPersistentStorage+Push.h"
#import "PMSSPushURLConnection.h"
#import "NSObject+PMSSJsonizable.h"
#import "PMSSPushRegistrationResponseData.h"
#import "NSURLConnection+PMSSBackEndConnection.h"
#import "PMSSPushDebug.h"
#import "PMSSPushErrorUtil.h"
#import "PMSSPushErrors.h"
#import "PMSSNotifications.h"

@implementation PMSSPushClient

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

- (PMSSAppDelegate *)swapAppDelegate
{
    PMSSAppDelegate *pushAppDelegate = [super swapAppDelegate];
    
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
    [PMSSPushURLConnection unregisterDeviceID:[PMSSPersistentStorage serverDeviceID]
                                  parameters:self.registrationParameters
                                     success:^(NSURLResponse *response, NSData *data) {
                                         [PMSSPersistentStorage resetPushPersistedValues];
                                         
                                         if (success) {
                                             success();
                                         }
                                         
                                         NSDictionary *userInfo = @{ @"URLResponse" : response };
                                         [[NSNotificationCenter defaultCenter] postNotificationName:PMSSPushUnregisterNotification object:self userInfo:userInfo];
                                     }
                                     failure:failure];
}

typedef void (^RegistrationBlock)(NSURLResponse *response, id responseData);

+ (RegistrationBlock)registrationBlockWithParameters:(PMSSParameters *)parameters
                                         deviceToken:(NSData *)deviceToken
                                             success:(void (^)(void))successBlock
                                             failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = ^(NSURLResponse *response, id responseData) {
        NSError *error;
        
        if (!responseData || ([responseData isKindOfClass:[NSData class]] && [(NSData *)responseData length] <= 0)) {
            error = [PMSSPushErrorUtil errorWithCode:PMSSPushBackEndRegistrationEmptyResponseData localizedDescription:@"Response body is empty when attempting registration with back-end server"];
            PMSSPushLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        PMSSPushRegistrationResponseData *parsedData = [PMSSPushRegistrationResponseData pmss_fromJSONData:responseData error:&error];
        
        if (error) {
            PMSSPushLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        if (!parsedData.deviceUUID) {
            error = [PMSSPushErrorUtil errorWithCode:PMSSPushBackEndRegistrationResponseDataNoDeviceUuid localizedDescription:@"Response body from registering with the back-end server does not contain an UUID "];
            PMSSPushLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        PMSSPushLog(@"Registration with back-end succeded. Device ID: \"%@\".", parsedData.deviceUUID);
        [PMSSPersistentStorage setAPNSDeviceToken:deviceToken];
        [PMSSPersistentStorage setServerDeviceID:parsedData.deviceUUID];
        [PMSSPersistentStorage setVariantUUID:parameters.variantUUID];
        [PMSSPersistentStorage setReleaseSecret:parameters.releaseSecret];
        [PMSSPersistentStorage setDeviceAlias:parameters.pushDeviceAlias];
        
        if (successBlock) {
            successBlock();
        }
        
        NSDictionary *userInfo = @{ @"URLResponse" : response };
        [[NSNotificationCenter defaultCenter] postNotificationName:PMSSPushRegistrationSuccessNotification object:self userInfo:userInfo];
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
        
        [PMSSPushURLConnection updateRegistrationWithDeviceID:[PMSSPersistentStorage serverDeviceID]
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

+ (void)sendRegisterRequestWithParameters:(PMSSParameters *)parameters
                              deviceToken:(NSData *)deviceToken
                                  success:(void (^)(void))successBlock
                                  failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = [self registrationBlockWithParameters:parameters
                                                                    deviceToken:deviceToken
                                                                        success:successBlock
                                                                        failure:failureBlock];
    [PMSSPushURLConnection registerWithParameters:parameters
                                    deviceToken:deviceToken
                                        success:registrationBlock
                                        failure:failureBlock];
}

+ (BOOL)updateRegistrationRequiredForDeviceToken:(NSData *)deviceToken
                                      parameters:(PMSSParameters *)parameters
{
    // If not currently registered with the back-end then update registration is not required
    if (![PMSSPersistentStorage APNSDeviceToken]) {
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
                                parameters:(PMSSParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if (![PMSSPersistentStorage serverDeviceID]) {
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

+ (BOOL)localParametersMatchNewParameters:(PMSSParameters *)parameters
{
    // If any of the registration parameters are different then unregistration is required
    if (![parameters.variantUUID isEqualToString:[PMSSPersistentStorage variantUUID]]) {
        PMSSPushLog(@"Parameters specify a different variantUUID. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.releaseSecret isEqualToString:[PMSSPersistentStorage releaseSecret]]) {
        PMSSPushLog(@"Parameters specify a different releaseSecret. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.pushDeviceAlias isEqualToString:[PMSSPersistentStorage deviceAlias]]) {
        PMSSPushLog(@"Parameters specify a different deviceAlias. Unregistration and re-registration will be required.");
        return NO;
    }
    
    return YES;
}

+ (BOOL)localDeviceTokenMatchesNewToken:(NSData *)deviceToken {
    if (![deviceToken isEqualToData:[PMSSPersistentStorage APNSDeviceToken]]) {
        PMSSPushLog(@"APNS returned a different APNS token. Unregistration and re-registration will be required.");
        return NO;
    }
    return YES;
}

@end
