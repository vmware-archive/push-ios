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
static PCFPushAppDelegateProxy *_appDelegateProxy;

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

+ (void)setRegistrationParameters:(PCFPushParameters *)parameters
                          success:(void (^)(void))success
                          failure:(void (^)(NSError *error))failure;
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters may not be nil."];
    }
    
    void (^successBlock)(NSData *deviceToken) = ^(NSData *deviceToken) {
        if (!deviceToken) {
            [NSException raise:NSInvalidArgumentException format:@"Device Token cannot not be nil."];
        }
        if (![deviceToken isKindOfClass:[NSData class]]) {
            [NSException raise:NSInvalidArgumentException format:@"Device Token type does not match expected type. NSData."];
        }
        
        if ([self updateRegistrationRequiredForDeviceToken:deviceToken parameters:parameters]) {
            [self sendUpdateRegistrationRequestWithParameters:parameters
                                                  deviceToken:deviceToken
                                                      success:success
                                                      failure:failure];
            
        } else if ([self registrationRequiredForDeviceToken:deviceToken parameters:parameters]) {
            [self sendRegisterRequestWithParameters:parameters
                                        deviceToken:deviceToken
                                            success:success
                                            failure:failure];
            
        } else if (success) {
            success();
        }
    };
    
    UIApplication *application = [UIApplication sharedApplication];
    PCFPushAppDelegate *pushAppDelegate;
    _appDelegateProxy = [[PCFPushAppDelegateProxy alloc] init];
    
    if (![application.delegate isKindOfClass:[PCFPushAppDelegateProxy class]]) {
        @synchronized(application) {
            pushAppDelegate = [[PCFPushAppDelegate alloc] init];
            _appDelegateProxy.originalAppDelegate = application.delegate;
            _appDelegateProxy.pushAppDelegate = pushAppDelegate;
            application.delegate = _appDelegateProxy;
        }
        
    } else {
        pushAppDelegate = (PCFPushAppDelegate *)[(PCFPushAppDelegateProxy *)application.delegate pushAppDelegate];
    }
    
    [pushAppDelegate setRegistrationBlockWithSuccess:successBlock failure:failure];
    
    // If the _registrationParameters, Back End Device ID, and APNS Device Token
    // are set then immediately attempt to update parameters on Push Server.
    if (_registrationParameters &&
        [PCFPushPersistentStorage pushServerDeviceID] &&
        [PCFPushPersistentStorage APNSDeviceToken])
    {
        successBlock([PCFPushPersistentStorage APNSDeviceToken]);
    }
    _registrationParameters = parameters;
}

+ (void)unregisterSuccess:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure
{
    [NSURLConnection pcf_unregisterDeviceID:[PCFPushPersistentStorage pushServerDeviceID]
                                    success:^(NSURLResponse *response, NSData *data) {
                                        [PCFPushPersistentStorage reset];
                                        success();
                                    }
                                    failure:failure];
}

#pragma mark - Private Methods

typedef void (^RegistrationBlock)(NSURLResponse *response, id responseData);

+ (void)sendUpdateRegistrationRequestWithParameters:(PCFPushParameters *)parameters
                                        deviceToken:(NSData *)deviceToken
                                            success:(void (^)(void))successBlock
                                            failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = [self registrationBlockWithParameters:parameters
                                                                    deviceToken:deviceToken
                                                                        success:successBlock
                                                                        failure:failureBlock];
    
    [NSURLConnection pcf_updateRegistrationWithDeviceID:[PCFPushPersistentStorage pushServerDeviceID]
                                             parameters:parameters
                                            deviceToken:deviceToken
                                                success:registrationBlock
                                                failure:failureBlock];
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
        [PCFPushPersistentStorage setAPNSDeviceToken:deviceToken];
        [PCFPushPersistentStorage setPushServerDeviceID:parsedData.deviceUUID];
        [PCFPushPersistentStorage setVariantUUID:parameters.variantUUID];
        [PCFPushPersistentStorage setReleaseSecret:parameters.releaseSecret];
        [PCFPushPersistentStorage setDeviceAlias:parameters.deviceAlias];
        
        successBlock();
    };
    
    return registrationBlock;
}

+ (void)sendRegisterRequestWithParameters:(PCFPushParameters *)parameters
                              deviceToken:(NSData *)deviceToken
                                  success:(void (^)(void))successBlock
                                  failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = [self registrationBlockWithParameters:parameters
                                                                    deviceToken:deviceToken
                                                                        success:successBlock
                                                                        failure:failureBlock];
    [NSURLConnection pcf_registerWithParameters:parameters
                                    deviceToken:deviceToken
                                        success:registrationBlock
                                        failure:failureBlock];
}

+ (void)registerForRemoteNotifications {
    if (_registrationParameters.remoteNotificationTypes != UIRemoteNotificationTypeNone) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:_registrationParameters.remoteNotificationTypes];
    }
}

+ (BOOL)updateRegistrationRequiredForDeviceToken:(NSData *)deviceToken
                                      parameters:(PCFPushParameters *)parameters
{
    // If not currently registered with the back-end then update registration is not required
    if (![PCFPushPersistentStorage APNSDeviceToken]) {
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
                                parameters:(PCFPushParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if (![PCFPushPersistentStorage pushServerDeviceID]) {
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

+ (BOOL)localParametersMatchNewParameters:(PCFPushParameters *)parameters
{
    // If any of the registration parameters are different then unregistration is required
    if (![parameters.variantUUID isEqualToString:[PCFPushPersistentStorage variantUUID]]) {
        PCFPushLog(@"Parameters specify a different variantUUID. Unregistration and re-registration will be required.");
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

+ (BOOL)localDeviceTokenMatchesNewToken:(NSData *)deviceToken {
    if (![deviceToken isEqualToData:[PCFPushPersistentStorage APNSDeviceToken]]) {
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

+ (BOOL)analyticsEnabled
{
    return [PCFPushPersistentStorage analyticsEnabled];
}

+ (void)setAnalyticsEnabled:(BOOL)enabled
{
    [PCFPushPersistentStorage setAnalyticsEnabled:enabled];
}

@end
