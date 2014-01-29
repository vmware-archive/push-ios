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

@end

@implementation OmniaPushRegistrationEngine

#pragma mark - Initialization and setup

- (instancetype) initWithApplication:(UIApplication*)application
         originalApplicationDelegate:(NSObject<UIApplicationDelegate>*)originalApplicationDelegate
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
    [self saveAPNSDeviceToken:apnsDeviceToken];
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

    [self saveBackEndDeviceId:responseData.deviceUuid];
    [self registrationSucceeded]; // TODO - move to later in the flow
}

- (void) backendRegistrationFailed:(NSError*)backendRegistrationError
{
    OmniaPushLog(@"Registration with back-end failed. Error: \"%@\".", backendRegistrationError.localizedDescription);
    self.error = backendRegistrationError;
    self.didFinishBackendRegistration = YES;
    self.didBackendRegistrationFail = YES;
    [self saveBackEndDeviceId:nil];
    [self registrationFailed]; // TODO - move to later in the flow
}

- (void) registrationSucceeded
{    
    self.didRegistrationSucceed = YES;
    OmniaPushRegistrationCompleteOperation *op = [[OmniaPushRegistrationCompleteOperation alloc] initWithApplication:self.application applicationDelegate:self.originalApplicationDelegate apnsDeviceToken:self.apnsDeviceToken];
    [[OmniaPushOperationQueueProvider workerQueue] addOperation:op];
}

- (void) registrationFailed
{
    self.didRegistrationFail = YES;
    OmniaPushRegistrationFailedOperation *op = [[OmniaPushRegistrationFailedOperation alloc] initWithApplication:self.application applicationDelegate:self.originalApplicationDelegate error:self.error];
    [[OmniaPushOperationQueueProvider workerQueue] addOperation:op];
}

#pragma mark - Helpers

- (void) saveAPNSDeviceToken:(NSData*)apnsDeviceToken
{
    OmniaPushPersistentStorage *storage = [[OmniaPushPersistentStorage alloc] init];
    [storage saveAPNSDeviceToken:apnsDeviceToken];
}

- (void) saveBackEndDeviceId:(NSString*)backEndDeviceId
{
    OmniaPushPersistentStorage *storage = [[OmniaPushPersistentStorage alloc] init];
    [storage saveBackEndDeviceID:backEndDeviceId];
}

@end
