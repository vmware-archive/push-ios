//
//  OmniaPushRegistrationEngine.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-24.
//  Copyright (c) 2014 Omnia. All rights reserved.
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
@property (nonatomic, readwrite) NSData *apnsDeviceToken;
@property (nonatomic, readwrite) NSError *error;
@property (nonatomic, readwrite) BOOL didStartRegistration;
@property (nonatomic, readwrite) BOOL didStartAPNSRegistration;
@property (nonatomic, readwrite) BOOL didFinishAPNSRegistration;
@property (nonatomic, readwrite) BOOL didAPNSRegistrationSucceed;
@property (nonatomic, readwrite) BOOL didAPNSRegistrationFail;
@property (nonatomic, readwrite) BOOL didStartBackendUnregistration;
@property (nonatomic, readwrite) BOOL didFinishBackendUnregistration;
@property (nonatomic, readwrite) BOOL didStartBackendRegistration;
@property (nonatomic, readwrite) BOOL didFinishBackendRegistration;
@property (nonatomic, readwrite) BOOL didBackendRegistrationSucceed;
@property (nonatomic, readwrite) BOOL didBackendRegistrationFail;
@property (nonatomic, readwrite) BOOL didRegistrationSucceed;
@property (nonatomic, readwrite) BOOL didRegistrationFail;
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
    self.apnsDeviceToken = apnsDeviceToken;
    self.didFinishAPNSRegistration = YES;
    self.didAPNSRegistrationSucceed = YES;

    if (![self isBackEndRegistrationRequiredWithNewDeviceToken:apnsDeviceToken]) {
        // Skip back-end registration and proceed to finish
        [self registrationSucceeded];
        return;
    }
    
    [self.storage saveAPNSDeviceToken:apnsDeviceToken];
    self.didStartBackendRegistration = YES;
    
    OmniaPushLog(@"Attempting registration with back-end server.");
    NSObject<OmniaPushBackEndRegistrationRequest> *request = [OmniaPushBackEndRegistrationRequestProvider request];
    [request startDeviceRegistration:apnsDeviceToken
                          parameters:self.parameters
                           onSuccess:^(OmniaPushBackEndRegistrationResponseData *responseData) {
                               [self backendRegistrationSucceeded:responseData];
                           }
                           onFailure:^(NSError *error) {
                               [self backendRegistrationFailed:error];
                           }];
    
}

- (void) apnsRegistrationFailed:(NSError*)apnsRegistrationError
{
    OmniaPushLog(@"Registration with APNS failed. Error: \"%@\".", apnsRegistrationError.localizedDescription);
    self.error = apnsRegistrationError;
    self.didFinishAPNSRegistration = YES;
    self.didAPNSRegistrationFail = YES;
    [self.storage saveAPNSDeviceToken:nil];

    [self registrationFailed]; // TODO - move to later in the flow
}

- (void) backendUnregistrationSucceeded
{
    
}

- (void) backendUnregistrationFailed:(NSError*)error
{
    
}

- (void) backendRegistrationSucceeded:(OmniaPushBackEndRegistrationResponseData*)responseData
{
    OmniaPushLog(@"Registration with back-end succeded. Device ID: \"%@\".", responseData.deviceUuid);
    self.didFinishBackendRegistration = YES;
    self.didBackendRegistrationSucceed = YES;

    [self.storage saveBackEndDeviceID:responseData.deviceUuid];
    [self registrationSucceeded]; // TODO - move to later in the flow
}

- (void) backendRegistrationFailed:(NSError*)backendRegistrationError
{
    OmniaPushLog(@"Registration with back-end failed. Error: \"%@\".", backendRegistrationError.localizedDescription);
    self.error = backendRegistrationError;
    self.didFinishBackendRegistration = YES;
    self.didBackendRegistrationFail = YES;
    [self.storage saveBackEndDeviceID:nil];
    [self registrationFailed]; // TODO - move to later in the flow
}

- (void) registrationSucceeded
{    
    self.didRegistrationSucceed = YES;
    OmniaPushRegistrationCompleteOperation *op = [[OmniaPushRegistrationCompleteOperation alloc] initWithApplication:self.application
                                                                                                 applicationDelegate:self.originalApplicationDelegate
                                                                                                     apnsDeviceToken:self.apnsDeviceToken
                                                                                                            listener:self.listener];
    [[OmniaPushOperationQueueProvider workerQueue] addOperation:op];
}

- (void) registrationFailed
{
    self.didRegistrationFail = YES;
    OmniaPushRegistrationFailedOperation *op = [[OmniaPushRegistrationFailedOperation alloc] initWithApplication:self.application
                                                                                             applicationDelegate:self.originalApplicationDelegate
                                                                                                           error:self.error
                                                                                                        listener:self.listener];
    [[OmniaPushOperationQueueProvider workerQueue] addOperation:op];
}

#pragma mark - Helpers

- (BOOL) isBackEndRegistrationRequiredWithNewDeviceToken:(NSData*)newApnsDeviceToken
{
    NSString *previousBackEndDeviceId = [self.storage loadBackEndDeviceID];
    if (previousBackEndDeviceId == nil) {
        return YES;
    }
    
    NSData *previousApnsDeviceToken = [self.storage loadAPNSDeviceToken];
    if (![newApnsDeviceToken isEqualToData:previousApnsDeviceToken]) {
        return YES;
    }
    
    OmniaPushLog(@"The new device token from APNS is the same as the old one. Back-end registration is not required.");
    return NO;
}

@end
