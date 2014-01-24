//
//  OmniaPushRegistrationEngine.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-24.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OmniaPushRegistrationParameters;

@interface OmniaPushRegistrationEngine : NSObject

@property (nonatomic, readonly) UIApplication *application;
@property (nonatomic, readonly) NSObject<UIApplicationDelegate> *originalApplicationDelegate;
@property (nonatomic, readonly) OmniaPushRegistrationParameters *parameters;
@property (nonatomic, readonly) NSData *apnsDeviceToken;
@property (nonatomic, readonly) NSError *apnsRegistrationError;
@property (nonatomic, readonly) BOOL didStartRegistration;
@property (nonatomic, readonly) BOOL didStartAPNSRegistration;
@property (nonatomic, readonly) BOOL didFinishAPNSRegistration;
@property (nonatomic, readonly) BOOL didAPNSRegistrationSucceed;
@property (nonatomic, readonly) BOOL didAPNSRegistrationFail;
@property (nonatomic, readonly) BOOL didStartBackendUnregistration;
@property (nonatomic, readonly) BOOL didFinishBackendUnregistration;
@property (nonatomic, readonly) BOOL didStartBackendRegistration;
@property (nonatomic, readonly) BOOL didFinishBackendRegistration;
@property (nonatomic, readonly) BOOL didRegistrationSucceed;
@property (nonatomic, readonly) BOOL didRegistrationFail;

- (instancetype) initWithApplication:(UIApplication*)application
         originalApplicationDelegate:(NSObject<UIApplicationDelegate>*)originalApplicationDelegate;

- (void) startRegistration:(OmniaPushRegistrationParameters*)parameters;
- (void) apnsRegistrationSucceeded:(NSData*)apnsDeviceToken;
- (void) apnsRegistrationFailed:(NSError*)apnsRegistrationError;
- (void) backendUnregistrationSucceeded;
- (void) backendUnregistrationFailed;
- (void) backendRegistrationSucceeded;
- (void) backendRegistrationFailed;
- (void) registrationSucceeded;
- (void) registrationFailed;

@end
