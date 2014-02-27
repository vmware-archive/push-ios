//
//  OmniaPushRegistrationEngine.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-24.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushRegistrationEngine.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaPushRegistrationFailedOperation.h"
#import "OmniaPushOperationQueueProvider.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaPushBackEndRegistrationRequest.h"
#import "OmniaPushBackEndRegistrationRequestProvider.h"
#import "OmniaPushBackEndRegistrationResponseData.h"
#import "OmniaPushBackEndUnregistrationRequest.h"
#import "OmniaPushBackEndUnregistrationRequestProvider.h"
#import "OmniaPushDebug.h"

/*
 
 [ APNS Registration Operation ]
    |
 < Succeeded? >
    |\
    | \ NO
YES |  \
    |   `> [ Registration Failed Operation ] ~~~> (END)
    V
 < Must unregister with backend? >
    |\
    | \ YES
 NO |  \
    |   `> Back-end Unregister Operation
    |        |
    |        V
    |    < Succeeded? >
    |        |\
    |        | \ NO
    |    YES |  \
    |        |   .
    V        V   V
 [ Back-end Registration Operation ]
    |
    V
 < Succeeded? >
    |\
    | \ NO
YES |  \
    |   `> [ Registration Failed Operation ] ~~~> (END)
    V
 [ Registration Complete Operation ] ~~~> (END)
 
 */

@interface OmniaPushRegistrationEngine ()

@property (nonatomic, readwrite) UIApplication *application;
@property (nonatomic, readwrite) NSObject<UIApplicationDelegate> *originalApplicationDelegate;
@property (nonatomic, readwrite, weak) id<OmniaPushRegistrationListener> listener;
@property (nonatomic, readwrite) OmniaPushRegistrationParameters *parameters;
@property (nonatomic, readwrite) NSString *originalBackEndDeviceId;
@property (nonatomic, readwrite) NSData *originalApnsDeviceToken;
@property (nonatomic, readwrite) NSData *updatedApnsDeviceToken;
@property (nonatomic, readwrite) NSString *originalReleaseUuid;
@property (nonatomic, readwrite) NSString *originalReleaseSecret;
@property (nonatomic, readwrite) NSString *originalDeviceAlias;
@property (nonatomic, readwrite) NSError *error;
@property (nonatomic, readwrite) BOOL didStartRegistration;
@property (nonatomic, readwrite) BOOL didStartAPNSRegistration;
@property (nonatomic, readwrite) BOOL didFinishAPNSRegistration;
@property (nonatomic, readwrite) BOOL didAPNSRegistrationSucceed;
@property (nonatomic, readwrite) BOOL didStartBackendUnregistration;
@property (nonatomic, readwrite) BOOL didFinishBackendUnregistration;
@property (nonatomic, readwrite) BOOL didStartBackendRegistration;
@property (nonatomic, readwrite) BOOL didFinishBackendRegistration;
@property (nonatomic, readwrite) BOOL didBackendRegistrationSucceed;
@property (nonatomic, readwrite) BOOL didBackEndUnregistrationSucceed;
@property (nonatomic, readwrite) BOOL didRegistrationSucceed;
@property (nonatomic) OmniaPushPersistentStorage *storage;

@end

@implementation OmniaPushRegistrationEngine

#pragma mark - Initialization and setup

- (instancetype) initWithApplication:(UIApplication*)application
         originalApplicationDelegate:(NSObject<UIApplicationDelegate>*)originalApplicationDelegate
                            listener:(id<OmniaPushRegistrationListener>)listener;
{
    self = [super init];
    if (self) {
        if (application == nil) {
            [NSException raise:NSInvalidArgumentException format:@"application may not be nil"];
        }
        if (originalApplicationDelegate == nil) {
            [NSException raise:NSInvalidArgumentException format:@"originalApplicationDelegate may not be nil"];
        }
        self.application = application;
        self.originalApplicationDelegate = originalApplicationDelegate;
        self.listener = listener;
        self.storage = [[OmniaPushPersistentStorage alloc] init];
    }
    return self;
}

#pragma mark - Registration entrypoint

- (void) startRegistration:(OmniaPushRegistrationParameters*)parameters
{
    if (parameters == nil) {
        [NSException raise:NSInvalidArgumentException format:@"parameters may not be nil"];
    }
    self.originalApnsDeviceToken = [self.storage loadAPNSDeviceToken];
    self.originalBackEndDeviceId = [self.storage loadBackEndDeviceID];
    self.originalReleaseUuid = [self.storage loadReleaseUuid];
    self.originalReleaseSecret = [self.storage loadReleaseSecret];
    self.originalDeviceAlias = [self.storage loadDeviceAlias];
    self.parameters = parameters;
    self.didStartRegistration = YES;
    self.didStartAPNSRegistration = YES;
    OmniaPushAPNSRegistrationRequestOperation *op = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithParameters:parameters application:self.application];
    [[OmniaPushOperationQueueProvider workerQueue] addOperation:op];
}

#pragma mark - State callbacks

- (void) apnsRegistrationSucceeded:(NSData*)apnsDeviceToken
{
    OmniaPushLog(@"Registration with APNS succeeded. Device token: \"%@\".", apnsDeviceToken);
    self.updatedApnsDeviceToken = apnsDeviceToken;
    self.didFinishAPNSRegistration = YES;
    self.didAPNSRegistrationSucceed = YES;
    [self.storage saveAPNSDeviceToken:apnsDeviceToken];

    if ([self isBackEndUnregistrationRequired]) {
        [self startBackEndUnregistration];
        return;
    }
    
    if (![self isBackEndRegistrationRequired]) {
        // Skip back-end registration and proceed to finish
        [self registrationSucceeded];
        return;
    }
    
    [self startBackEndRegistration];
}

- (void) apnsRegistrationFailed:(NSError*)apnsRegistrationError
{
    OmniaPushCriticalLog(@"Registration with APNS failed. Error: \"%@\".", apnsRegistrationError.localizedDescription);
    self.error = apnsRegistrationError;
    self.didFinishAPNSRegistration = YES;
    self.didAPNSRegistrationSucceed = NO;
    [self.storage saveAPNSDeviceToken:nil];
    [self registrationFailed];
}

- (void) backendUnregistrationSucceeded
{
    OmniaPushLog(@"Unregistration with the back-end server succeeded.");
    self.didFinishBackendUnregistration = YES;
    self.didBackEndUnregistrationSucceed = YES;
    [self startBackEndRegistration];
}

- (void) backendUnregistrationFailed:(NSError*)error
{
    OmniaPushLog(@"Unregistration with the back-end server failed. Error: \"%@\".", error.localizedDescription);
    OmniaPushLog(@"Nevertheless, registration will be attempted.");
    self.didFinishBackendUnregistration = YES;
    self.didBackEndUnregistrationSucceed = NO;
    [self startBackEndRegistration];
}

- (void) backendRegistrationSucceeded:(OmniaPushBackEndRegistrationResponseData*)responseData
{
    OmniaPushLog(@"Registration with back-end succeded. Device ID: \"%@\".", responseData.deviceUuid);
    self.didFinishBackendRegistration = YES;
    self.didBackendRegistrationSucceed = YES;

    [self.storage saveBackEndDeviceID:responseData.deviceUuid];
    [self.storage saveReleaseUuid:self.parameters.releaseUuid];
    [self.storage saveReleaseSecret:self.parameters.releaseSecret];
    [self.storage saveDeviceAlias:self.parameters.deviceAlias];

    [self registrationSucceeded];
}

- (void) backendRegistrationFailed:(NSError*)backendRegistrationError
{
    OmniaPushCriticalLog(@"Registration with back-end failed. Error: \"%@\".", backendRegistrationError.localizedDescription);
    self.error = backendRegistrationError;
    self.didFinishBackendRegistration = YES;
    self.didBackendRegistrationSucceed = NO;
    
    [self.storage saveBackEndDeviceID:nil];
    [self.storage saveReleaseUuid:nil];
    [self.storage saveReleaseSecret:nil];
    [self.storage saveDeviceAlias:nil];

    [self registrationFailed];
}

- (void) registrationSucceeded
{
    self.didRegistrationSucceed = YES;
    OmniaPushRegistrationCompleteOperation *op = [[OmniaPushRegistrationCompleteOperation alloc] initWithApplication:self.application
                                                                                                 applicationDelegate:self.originalApplicationDelegate
                                                                                                     apnsDeviceToken:self.updatedApnsDeviceToken
                                                                                                            listener:self.listener];
    [[OmniaPushOperationQueueProvider workerQueue] addOperation:op];
}

- (void) registrationFailed
{
    self.didRegistrationSucceed = NO;
    OmniaPushRegistrationFailedOperation *op = [[OmniaPushRegistrationFailedOperation alloc] initWithApplication:self.application
                                                                                             applicationDelegate:self.originalApplicationDelegate
                                                                                                           error:self.error
                                                                                                        listener:self.listener];
    [[OmniaPushOperationQueueProvider workerQueue] addOperation:op];
}

#pragma mark - Helpers

- (BOOL) isBackEndUnregistrationRequired
{
    // If not currently registered with the back-end then unregistration is not required
    if (self.originalBackEndDeviceId == nil) {
        return NO;
    }
    
    // If the new device token is different from as the previous one then unregistration is required
    if (![self.updatedApnsDeviceToken isEqualToData:self.originalApnsDeviceToken]) {
        OmniaPushLog(@"APNS returned a different APNS token. Unregistration and re-registration will be required.");
        return YES;
    }
    
    // If any of the registration parameters are different then unregistration is required
    if (![self.parameters.releaseUuid isEqualToString:self.originalReleaseUuid]) {
        OmniaPushLog(@"Parameters specify a different releaseUuid. Unregistration and re-registration will be required.");
        return YES;
    }
    
    if (![self.parameters.releaseSecret isEqualToString:self.originalReleaseSecret]) {
        OmniaPushLog(@"Parameters specify a different releaseSecret. Unregistration and re-registration will be required.");
        return YES;
    }
    
    if (![self.parameters.deviceAlias isEqualToString:self.originalDeviceAlias]) {
        OmniaPushLog(@"Parameters specify a different deviceAlias. Unregistration and re-registration will be required.");
        return YES;
    }

    return NO;
}

- (BOOL) isBackEndRegistrationRequired
{
    // If not currently registered with the back-end then registration will be required
    if (self.originalBackEndDeviceId == nil) {
        return YES;
    }
    
    // If the new device token is different from the old one then a new registration with the back-end will be required
    if (![self.updatedApnsDeviceToken isEqualToData:self.originalApnsDeviceToken]) {
        return YES;
    }

    // If any of the registration parameters are different then unregistration is required
    if (![self.parameters.releaseUuid isEqualToString:self.originalReleaseUuid]) {
        return YES;
    }
    
    if (![self.parameters.releaseSecret isEqualToString:self.originalReleaseSecret]) {
        return YES;
    }
    
    if (![self.parameters.deviceAlias isEqualToString:self.originalDeviceAlias]) {
        return YES;
    }
    
    OmniaPushLog(@"The new device token from APNS is the same as the old one. Back-end registration is not required.");
    return NO;
}


- (void) startBackEndUnregistration
{
    self.didStartBackendUnregistration = YES;
    [self.storage saveBackEndDeviceID:nil];
    NSString *previousBackEndDeviceId = self.originalBackEndDeviceId;
    OmniaPushLog(@"Attempting unregistration with back-end server for back-end device ID \"%@\".", previousBackEndDeviceId);
    
    NSObject<OmniaPushBackEndUnregistrationRequest> *request = [OmniaPushBackEndUnregistrationRequestProvider request];
    [request startDeviceUnregistration:previousBackEndDeviceId
                             onSuccess:^{
                                 [self backendUnregistrationSucceeded];
                             }
                             onFailure:^(NSError *error) {
                                 [self backendUnregistrationFailed:error];
                             }];
}

- (void) startBackEndRegistration
{
    self.didStartBackendRegistration = YES;
    OmniaPushLog(@"Attempting registration with back-end server.");
    NSObject<OmniaPushBackEndRegistrationRequest> *request = [OmniaPushBackEndRegistrationRequestProvider request];
    [request startDeviceRegistration:self.updatedApnsDeviceToken
                          parameters:self.parameters
                           onSuccess:^(OmniaPushBackEndRegistrationResponseData *responseData) {
                               [self backendRegistrationSucceeded:responseData];
                           }
                           onFailure:^(NSError *error) {
                               [self backendRegistrationFailed:error];
                           }];
}

@end
