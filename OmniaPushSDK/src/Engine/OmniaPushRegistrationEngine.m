//
//  OmniaPushRegistrationEngine.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-24.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushRegistrationEngine.h"
#import "OmniaPushRegistrationParameters.h"


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
@property (nonatomic, readwrite) OmniaPushRegistrationParameters *parameters;
@property (nonatomic, readwrite) BOOL didStartRegistration;
@property (nonatomic, readwrite) BOOL didStartAPNSRegistration;
@property (nonatomic, readwrite) BOOL didFinishAPNSRegistration;
@property (nonatomic, readwrite) BOOL didStartBackendUnregistration;
@property (nonatomic, readwrite) BOOL didFinishBackendUnregistration;
@property (nonatomic, readwrite) BOOL didStartBackendRegistration;
@property (nonatomic, readwrite) BOOL didFinishBackendRegistration;
@property (nonatomic, readwrite) BOOL didRegistrationSucceed;
@property (nonatomic, readwrite) BOOL didRegistrationFail;

@end

@implementation OmniaPushRegistrationEngine

#pragma mark - Initialization and setup

- (instancetype) initWithApplication:(UIApplication*)application
{
    self = [super init];
    if (self) {
        if (application == nil) {
            [NSException raise:NSInvalidArgumentException format:@"application may not be nil"];
        }
        self.application = application;
    }
    return self;
}

#pragma mark - Registration entrypoint

- (void) startRegistration:(OmniaPushRegistrationParameters*)parameters
{
    
}

#pragma mark - State callbacks

- (void) apnsRegistrationComplete
{
    
}

- (void) backendUnregistrationComplete
{
    
}

- (void) backendRegistrationComplete
{
    
}

#pragma mark - helpers
@end
