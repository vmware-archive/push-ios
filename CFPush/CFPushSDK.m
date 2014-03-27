//
//  CFPushSDK.m
//  CFPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "NSURLConnection+CFPushBackEndConnection.h"
#import "CFPushRegistrationResponseData.h"
#import "CFPushParameters.h"
#import "CFPushPersistentStorage.h"
#import "CFAppDelegate.h"
#import "CFAppDelegateProxy.h"
#import "CFPushErrorUtil.h"
#import "CFPushErrors.h"
#import "CFPushDebug.h"
#import "CFPushSDK.h"


NSString *const CFPushErrorDomain = @"CFPushErrorDomain";

static CFPushParameters *_registrationParameters;

@implementation CFPushSDK

#pragma mark - Public Methods

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserver:[self class]
                                             selector:@selector(appDidFinishLaunchingNotification:)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:[self class]
                                             selector:@selector(appWillTerminateNotification:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

+ (void)registerWithParameters:(CFPushParameters *)parameters
                       success:(void (^)(void))success
                       failure:(void (^)(NSError *error))failure;
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"parameters may not be nil"];
    }
    
    void (^successBlock)(NSData *devToken) = ^(NSData *devToken) {
        if ([self unregistrationRequiredForDevToken:devToken parameters:parameters]) {
            [self.class sendUnregisterRequestWithParameters:parameters
                                                   devToken:devToken
                                               successBlock:success
                                               failureBlock:failure];
            
        } else if ([self registrationRequiredForDevToken:devToken parameters:parameters]) {
            [self.class sendRegisterRequestWithParameters:parameters
                                                 devToken:devToken
                                             successBlock:success
                                             failureBlock:failure];
        } else if (success) {
            success();
        }
    };
    
    UIApplication *application = [UIApplication sharedApplication];
    CFAppDelegate *cfAppDelegate;
    if (![application.delegate isKindOfClass:[CFAppDelegateProxy class]]) {
        @synchronized(application) {
            CFAppDelegateProxy *appDelegateProxy = [[CFAppDelegateProxy alloc] init];
            cfAppDelegate = [[CFAppDelegate alloc] init];
            appDelegateProxy.cfAppDelegate = cfAppDelegate;
            appDelegateProxy.originalAppDelegate = application.delegate;
            application.delegate = appDelegateProxy;
        }
        
    } else {
        cfAppDelegate = (CFAppDelegate *)[(CFAppDelegateProxy *)application.delegate cfAppDelegate];
    }
    
    [cfAppDelegate setRegistrationBlockWithSuccess:successBlock
                                           failure:failure];
    
    _registrationParameters = parameters;
}

+ (void)unregisterSuccess:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure
{
    [NSURLConnection cf_unregisterDeviceID:[CFPushPersistentStorage backEndDeviceID]
                                      success:^(NSURLResponse *response, NSData *data) {
                                          [CFPushPersistentStorage reset];
                                          success();
                                      }
                                      failure:failure];
}

#pragma mark - Private Methods

+ (void)sendUnregisterRequestWithParameters:(CFPushParameters *)parameters
                                   devToken:(NSData *)devToken
                               successBlock:(void (^)(void))successBlock
                               failureBlock:(void (^)(NSError *error))failureBlock
{
    [NSURLConnection cf_unregisterDeviceID:[CFPushPersistentStorage backEndDeviceID]
                                      success:^(NSURLResponse *response, NSData *data) {
                                          CFPushCriticalLog(@"Unregistration with the back-end server succeeded.");
                                          [self sendRegisterRequestWithParameters:parameters devToken:devToken successBlock:successBlock failureBlock:failureBlock];
                                      }
                                      failure:^(NSError *error) {
                                          CFPushCriticalLog(@"Unregistration with the back-end server failed. Error: \"%@\".", error.localizedDescription);
                                          CFPushLog(@"Nevertheless, registration will be attempted.");
                                          [self sendRegisterRequestWithParameters:parameters devToken:devToken successBlock:successBlock failureBlock:failureBlock];
                                      }];
}

+ (void)sendRegisterRequestWithParameters:(CFPushParameters *)parameters
                                 devToken:(NSData *)devToken
                             successBlock:(void (^)(void))successBlock
                             failureBlock:(void (^)(NSError *error))failureBlock
{
    void (^registrationSuccessfulBlock)(NSURLResponse *response, id responseData) = registrationSuccessfulBlock = ^(NSURLResponse *response, id responseData) {
        NSError *error;
        
        if ([self successfulStatusForHTTPResponse:(NSHTTPURLResponse *)response]) {
            error = [CFPushErrorUtil errorWithCode:CFPushBackEndRegistrationFailedHTTPStatusCode localizedDescription:@"Failed HTTP Status Code"];
            failureBlock(error);
            return;
        }
        
        if (!responseData || ([responseData isKindOfClass:[NSData class]] && [(NSData *)responseData length] <= 0)) {
            error = [CFPushErrorUtil errorWithCode:CFPushBackEndRegistrationEmptyResponseData localizedDescription:@"Response body is empty when attempting registration with back-end server"];
            failureBlock(error);
            return;
        }
        
        CFPushRegistrationResponseData *parsedData = [CFPushRegistrationResponseData fromJSONData:responseData error:&error];
        
        if (error) {
            failureBlock(error);
            return;
        }
        
        if (!parsedData.deviceUUID) {
            error = [CFPushErrorUtil errorWithCode:CFPushBackEndRegistrationResponseDataNoDeviceUuid localizedDescription:@"Response body from registering with the back-end server does not contain an UUID "];
            failureBlock(error);
            return;
        }
        
        CFPushCriticalLog(@"Registration with back-end succeded. Device ID: \"%@\".", parsedData.deviceUUID);
        [CFPushPersistentStorage setBackEndDeviceID:parsedData.deviceUUID];
        [CFPushPersistentStorage setReleaseUUID:parameters.releaseUUID];
        [CFPushPersistentStorage setReleaseSecret:parameters.releaseSecret];
        [CFPushPersistentStorage setDeviceAlias:parameters.deviceAlias];
        
        successBlock();
    };
    [NSURLConnection cf_registerWithParameters:parameters
                                         devToken:devToken
                                          success:registrationSuccessfulBlock
                                          failure:failureBlock];
}

+ (BOOL)successfulStatusForHTTPResponse:(NSHTTPURLResponse *)response {
    return [response isKindOfClass:[NSHTTPURLResponse class]] && ([response statusCode] < 200 || [response statusCode] >= 300);
}

+ (void)registerForRemoteNotifications {
    if (_registrationParameters.remoteNotificationTypes != UIRemoteNotificationTypeNone) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:_registrationParameters.remoteNotificationTypes];
    }
}

+ (BOOL)unregistrationRequiredForDevToken:(NSData *)devToken
                               parameters:(CFPushParameters *)parameters
{
    // If not currently registered with the back-end then unregistration is not required
    if (![CFPushPersistentStorage APNSDeviceToken]) {
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
                             parameters:(CFPushParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if (![CFPushPersistentStorage backEndDeviceID]) {
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

+ (BOOL)localParametersMatchNewParameters:(CFPushParameters *)parameters
{
    // If any of the registration parameters are different then unregistration is required
    if (![parameters.releaseUUID isEqualToString:[CFPushPersistentStorage releaseUUID]]) {
        CFPushLog(@"Parameters specify a different releaseUUID. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.releaseSecret isEqualToString:[CFPushPersistentStorage releaseSecret]]) {
        CFPushLog(@"Parameters specify a different releaseSecret. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.deviceAlias isEqualToString:[CFPushPersistentStorage deviceAlias]]) {
        CFPushLog(@"Parameters specify a different deviceAlias. Unregistration and re-registration will be required.");
        return NO;
    }
    
    return YES;
}

+ (BOOL)localDeviceTokenMatchesNewToken:(NSData *)devToken {
    if (![devToken isEqualToData:[CFPushPersistentStorage APNSDeviceToken]]) {
        CFPushLog(@"APNS returned a different APNS token. Unregistration and re-registration will be required.");
        return NO;
    }
    return YES;
}

#pragma mark - Notification Handler Methods

+ (void)appDidFinishLaunchingNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class] name:UIApplicationDidFinishLaunchingNotification object:nil];
    
    if (!_registrationParameters) {
        CFPushLog(@"registerWithParameters:success:failure: was not called in application:didFinishLaunchingWithOptions:");
        return;
    }
    
    [self registerForRemoteNotifications];
}

+ (void)appWillTerminateNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class] name:UIApplicationWillTerminateNotification object:nil];
    
    UIApplication *application = [UIApplication sharedApplication];
    if ([application.delegate isKindOfClass:[CFAppDelegateProxy class]]) {
        @synchronized (application) {
            CFAppDelegateProxy *proxyDelegate = application.delegate;
            application.delegate = proxyDelegate.originalAppDelegate;
        }
    }
}

@end
