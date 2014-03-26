//
//  OmniaPushSDK.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "NSURLConnection+OmniaPushBackEndConnection.h"
#import "OmniaPushSDK.h"
#import "OmniaApplicationDelegate.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaPushDebug.h"
#import "OmniaPushErrorUtil.h"
#import "OmniaPushErrors.h"
#import "OmniaPushBackEndRegistrationResponseData.h"

NSString *const OmniaPushErrorDomain = @"OmniaPushErrorDomain";

@implementation OmniaPushSDK

#pragma mark - Public Methods

+ (void)registerWithParameters:(OmniaPushRegistrationParameters *)parameters
                       success:(void (^)(void))success
                       failure:(void (^)(NSError *error))failure;
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"parameters may not be nil"];
    }

    [OmniaPushSDK registerWithAPNSWithParameters:parameters
                                    successBlock:success
                                    failureBlock:failure];
}

+ (void)unregisterSuccess:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure
{
    [NSURLConnection omnia_unregisterDeviceID:[OmniaPushPersistentStorage backEndDeviceID]
                                      success:^(NSURLResponse *response, NSData *data) {
                                          [OmniaPushPersistentStorage reset];
                                          success();
                                      }
                                      failure:failure];
}

#pragma mark - Private Methods

+ (void)sendUnregisterRequestWithParameters:(OmniaPushRegistrationParameters *)parameters
                                   devToken:(NSData *)devToken
                               successBlock:(void (^)(void))successBlock
                               failureBlock:(void (^)(NSError *error))failureBlock
{
    [NSURLConnection omnia_unregisterDeviceID:[OmniaPushPersistentStorage backEndDeviceID]
                                      success:^(NSURLResponse *response, NSData *data) {
                                          OmniaPushCriticalLog(@"Unregistration with the back-end server succeeded.");
                                          [self sendRegisterRequestWithParameters:parameters devToken:devToken successBlock:successBlock failureBlock:failureBlock];
                                      }
                                      failure:^(NSError *error) {
                                          OmniaPushCriticalLog(@"Unregistration with the back-end server failed. Error: \"%@\".", error.localizedDescription);
                                          OmniaPushLog(@"Nevertheless, registration will be attempted.");
                                          [self sendRegisterRequestWithParameters:parameters devToken:devToken successBlock:successBlock failureBlock:failureBlock];
                                      }];
}

+ (void)sendRegisterRequestWithParameters:(OmniaPushRegistrationParameters *)parameters
                                 devToken:(NSData *)devToken
                             successBlock:(void (^)(void))successBlock
                             failureBlock:(void (^)(NSError *error))failureBlock
{
    void (^registrationSuccessfulBlock)(NSURLResponse *response, id responseData) = registrationSuccessfulBlock = ^(NSURLResponse *response, id responseData) {
        NSError *error;
        
        if ([self successfulStatusForHTTPResponse:(NSHTTPURLResponse *)response]) {
            error = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationFailedHTTPStatusCode localizedDescription:@"Failed HTTP Status Code"];
            failureBlock(error);
            return;
        }
        
        if (!responseData || ([responseData isKindOfClass:[NSData class]] && [(NSData *)responseData length] <= 0)) {
            error = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationEmptyResponseData localizedDescription:@"Response body is empty when attempting registration with back-end server"];
            failureBlock(error);
            return;
        }
        
        OmniaPushBackEndRegistrationResponseData *parsedData = [OmniaPushBackEndRegistrationResponseData fromJSONData:responseData error:&error];
        
        if (error) {
            failureBlock(error);
            return;
        }
        
        if (!parsedData.deviceUUID) {
            error = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationResponseDataNoDeviceUuid localizedDescription:@"Response body from registering with the back-end server does not contain an UUID "];
            failureBlock(error);
            return;
        }
        
        OmniaPushCriticalLog(@"Registration with back-end succeded. Device ID: \"%@\".", parsedData.deviceUUID);
        [OmniaPushPersistentStorage setBackEndDeviceID:parsedData.deviceUUID];
        [OmniaPushPersistentStorage setReleaseUUID:parameters.releaseUUID];
        [OmniaPushPersistentStorage setReleaseSecret:parameters.releaseSecret];
        [OmniaPushPersistentStorage setDeviceAlias:parameters.deviceAlias];
        
        successBlock();
    };
    [NSURLConnection omnia_registerWithParameters:parameters
                                         devToken:devToken
                                          success:registrationSuccessfulBlock
                                          failure:failureBlock];
}

+ (BOOL)successfulStatusForHTTPResponse:(NSHTTPURLResponse *)response {
    return [response isKindOfClass:[NSHTTPURLResponse class]] && ([response statusCode] < 200 || [response statusCode] >= 300);
}

+ (void)registerWithAPNSWithParameters:(OmniaPushRegistrationParameters *)parameters
                          successBlock:(void (^)(void))successBlock
                          failureBlock:(void (^)(NSError *error))failureBlock
{
    void (^success)(NSData *devToken) = ^(NSData *devToken) {
        if ([self unregistrationRequiredForDevToken:devToken parameters:parameters]) {
            [self.class sendUnregisterRequestWithParameters:parameters
                                                   devToken:devToken
                                               successBlock:successBlock
                                               failureBlock:failureBlock];
            
        } else if ([self registrationRequiredForDevToken:devToken parameters:parameters]) {
            [self.class sendRegisterRequestWithParameters:parameters
                                                 devToken:devToken
                                             successBlock:successBlock
                                             failureBlock:failureBlock];
            
        } else {
            successBlock();
        }
    };
    
    void (^failure)(NSError *error) = ^(NSError *error) {
        failureBlock(error);
    };
    
    [[OmniaApplicationDelegate omniaApplicationDelegate] registerWithApplication:[UIApplication sharedApplication]
                                                         remoteNotificationTypes:parameters.remoteNotificationTypes
                                                                         success:success
                                                                         failure:failure];
}

+ (BOOL)unregistrationRequiredForDevToken:(NSData *)devToken
                               parameters:(OmniaPushRegistrationParameters *)parameters
{
    // If not currently registered with the back-end then unregistration is not required
    if (![OmniaPushPersistentStorage APNSDeviceToken]) {
        return NO;
    }
    
    if (![self localDeviceTokenMatchesNewToken:devToken]) {
        return YES;
    }
    
    if (![self localParametersMatchNewParameters:parameters]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)registrationRequiredForDevToken:(NSData *)devToken
                             parameters:(OmniaPushRegistrationParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if (![OmniaPushPersistentStorage backEndDeviceID]) {
        return YES;
    }
    
    if (![self localDeviceTokenMatchesNewToken:devToken]) {
        return YES;
    }
    
    if (![self localParametersMatchNewParameters:parameters]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)localParametersMatchNewParameters:(OmniaPushRegistrationParameters *)parameters
{
    // If any of the registration parameters are different then unregistration is required
    if (![parameters.releaseUUID isEqualToString:[OmniaPushPersistentStorage releaseUUID]]) {
        OmniaPushLog(@"Parameters specify a different releaseUUID. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.releaseSecret isEqualToString:[OmniaPushPersistentStorage releaseSecret]]) {
        OmniaPushLog(@"Parameters specify a different releaseSecret. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.deviceAlias isEqualToString:[OmniaPushPersistentStorage deviceAlias]]) {
        OmniaPushLog(@"Parameters specify a different deviceAlias. Unregistration and re-registration will be required.");
        return NO;
    }
    
    return YES;
}

+ (BOOL)localDeviceTokenMatchesNewToken:(NSData *)devToken {
    if (![devToken isEqualToData:[OmniaPushPersistentStorage APNSDeviceToken]]) {
        OmniaPushLog(@"APNS returned a different APNS token. Unregistration and re-registration will be required.");
        return NO;
    }
    return YES;
}

@end
