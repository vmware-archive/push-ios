//
//  PCFPushSDK.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "NSURLConnection+PCFPushBackEndConnection.h"
#import "NSObject+PCFPushJsonizable.h"
#import "PCFPushRegistrationResponseData.h"
#import "PCFPushParameters.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushAppDelegate.h"
#import "PCFPushAppDelegateProxy.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushErrors.h"
#import "PCFPushDebug.h"
#import "PCFPushSDK.h"


NSString *const PCFPushErrorDomain = @"PCFPushErrorDomain";

static PCFPushParameters *_registrationParameters;

@implementation PCFPushSDK

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

+ (void)registerWithParameters:(PCFPushParameters *)parameters
                       success:(void (^)(void))success
                       failure:(void (^)(NSError *error))failure;
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters may not be nil."];
    }
    
    void (^successBlock)(NSData *devToken) = ^(NSData *devToken) {
        if ([self unregistrationRequiredForDevToken:devToken parameters:parameters]) {
            [self sendUnregisterRequestWithParameters:parameters
                                             devToken:devToken
                                              success:success
                                              failure:failure];
            
        } else if ([self registrationRequiredForDevToken:devToken parameters:parameters]) {
            [self sendRegisterRequestWithParameters:parameters
                                           devToken:devToken
                                            success:success
                                            failure:failure];
            
        } else if (success) {
            success();
        }
    };
    
    UIApplication *application = [UIApplication sharedApplication];
    PCFPushAppDelegate *pushAppDelegate;
    if (![application.delegate isKindOfClass:[PCFPushAppDelegateProxy class]]) {
        @synchronized(application) {
            PCFPushAppDelegateProxy *appDelegateProxy = [[PCFPushAppDelegateProxy alloc] init];
            pushAppDelegate = [[PCFPushAppDelegate alloc] init];
            appDelegateProxy.pushAppDelegate = pushAppDelegate;
            appDelegateProxy.originalAppDelegate = application.delegate;
            application.delegate = appDelegateProxy;
        }
        
    } else {
        pushAppDelegate = (PCFPushAppDelegate *)[(PCFPushAppDelegateProxy *)application.delegate pushAppDelegate];
    }
    
    [pushAppDelegate setRegistrationBlockWithSuccess:successBlock failure:failure];
    
    _registrationParameters = parameters;
}

+ (void)unregisterSuccess:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure
{
    [NSURLConnection pcf_unregisterDeviceID:[PCFPushPersistentStorage backEndDeviceID]
                                      success:^(NSURLResponse *response, NSData *data) {
                                          [PCFPushPersistentStorage reset];
                                          success();
                                      }
                                      failure:failure];
}

#pragma mark - Private Methods

+ (void)sendUnregisterRequestWithParameters:(PCFPushParameters *)parameters
                                   devToken:(NSData *)devToken
                               success:(void (^)(void))successBlock
                               failure:(void (^)(NSError *error))failureBlock
{
    [NSURLConnection pcf_unregisterDeviceID:[PCFPushPersistentStorage backEndDeviceID]
                                      success:^(NSURLResponse *response, NSData *data) {
                                          PCFPushCriticalLog(@"Unregistration with the back-end server succeeded.");
                                          [self sendRegisterRequestWithParameters:parameters devToken:devToken success:successBlock failure:failureBlock];
                                      }
                                      failure:^(NSError *error) {
                                          PCFPushCriticalLog(@"Unregistration with the back-end server failed. Error: \"%@\".", error.localizedDescription);
                                          PCFPushLog(@"Nevertheless, registration will be attempted.");
                                          [self sendRegisterRequestWithParameters:parameters devToken:devToken success:successBlock failure:failureBlock];
                                      }];
}

+ (void)sendRegisterRequestWithParameters:(PCFPushParameters *)parameters
                                 devToken:(NSData *)devToken
                             success:(void (^)(void))successBlock
                             failure:(void (^)(NSError *error))failureBlock
{
    void (^registrationSuccessfulBlock)(NSURLResponse *response, id responseData) = registrationSuccessfulBlock = ^(NSURLResponse *response, id responseData) {
        NSError *error;
        
        if (!responseData || ([responseData isKindOfClass:[NSData class]] && [(NSData *)responseData length] <= 0)) {
            error = [PCFPushErrorUtil errorWithCode:PCFPushBackEndRegistrationEmptyResponseData localizedDescription:@"Response body is empty when attempting registration with back-end server"];
            failureBlock(error);
            return;
        }
        
        PCFPushRegistrationResponseData *parsedData = [PCFPushRegistrationResponseData fromJSONData:responseData error:&error];
        
        if (error) {
            failureBlock(error);
            return;
        }
        
        if (!parsedData.deviceUUID) {
            error = [PCFPushErrorUtil errorWithCode:PCFPushBackEndRegistrationResponseDataNoDeviceUuid localizedDescription:@"Response body from registering with the back-end server does not contain an UUID "];
            failureBlock(error);
            return;
        }
        
        PCFPushCriticalLog(@"Registration with back-end succeded. Device ID: \"%@\".", parsedData.deviceUUID);
        [PCFPushPersistentStorage setBackEndDeviceID:parsedData.deviceUUID];
        [PCFPushPersistentStorage setReleaseUUID:parameters.releaseUUID];
        [PCFPushPersistentStorage setReleaseSecret:parameters.releaseSecret];
        [PCFPushPersistentStorage setDeviceAlias:parameters.deviceAlias];
        
        successBlock();
    };
    [NSURLConnection pcf_registerWithParameters:parameters
                                      devToken:devToken
                                       success:registrationSuccessfulBlock
                                       failure:failureBlock];
}

+ (void)registerForRemoteNotifications {
    if (_registrationParameters.remoteNotificationTypes != UIRemoteNotificationTypeNone) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:_registrationParameters.remoteNotificationTypes];
    }
}

+ (BOOL)unregistrationRequiredForDevToken:(NSData *)devToken
                               parameters:(PCFPushParameters *)parameters
{
    // If not currently registered with the back-end then unregistration is not required
    if (![PCFPushPersistentStorage APNSDeviceToken]) {
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
                             parameters:(PCFPushParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if (![PCFPushPersistentStorage backEndDeviceID]) {
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

+ (BOOL)localParametersMatchNewParameters:(PCFPushParameters *)parameters
{
    // If any of the registration parameters are different then unregistration is required
    if (![parameters.releaseUUID isEqualToString:[PCFPushPersistentStorage releaseUUID]]) {
        PCFPushLog(@"Parameters specify a different releaseUUID. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.releaseSecret isEqualToString:[PCFPushPersistentStorage releaseSecret]]) {
        PCFPushLog(@"Parameters specify a different releaseSecret. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.deviceAlias isEqualToString:[PCFPushPersistentStorage deviceAlias]]) {
        PCFPushLog(@"Parameters specify a different deviceAlias. Unregistration and re-registration will be required.");
        return NO;
    }
    
    return YES;
}

+ (BOOL)localDeviceTokenMatchesNewToken:(NSData *)devToken {
    if (![devToken isEqualToData:[PCFPushPersistentStorage APNSDeviceToken]]) {
        PCFPushLog(@"APNS returned a different APNS token. Unregistration and re-registration will be required.");
        return NO;
    }
    return YES;
}

#pragma mark - Notification Handler Methods

+ (void)appDidFinishLaunchingNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class] name:UIApplicationDidFinishLaunchingNotification object:nil];
    
    if (!_registrationParameters) {
        PCFPushLog(@"registerWithParameters:success:failure: was not called in application:didFinishLaunchingWithOptions:");
        return;
    }
    
    [self registerForRemoteNotifications];
}

+ (void)appWillTerminateNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class] name:UIApplicationWillTerminateNotification object:nil];
    
    UIApplication *application = [UIApplication sharedApplication];
    if ([application.delegate isKindOfClass:[PCFPushAppDelegateProxy class]]) {
        @synchronized (application) {
            PCFPushAppDelegateProxy *proxyDelegate = application.delegate;
            application.delegate = proxyDelegate.originalAppDelegate;
        }
    }
}

@end
