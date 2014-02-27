//
//  OmniaPushRegistrationEngine.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-24.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OmniaPushRegistrationListener;
@class OmniaPushRegistrationParameters;
@class OmniaPushBackEndRegistrationResponseData;

@interface OmniaPushRegistrationEngine : NSObject

@property (nonatomic, readonly) UIApplication *application;
@property (nonatomic, readonly) NSObject<UIApplicationDelegate> *originalApplicationDelegate;
@property (nonatomic, readonly, weak) id<OmniaPushRegistrationListener> listener;
@property (nonatomic, readonly) OmniaPushRegistrationParameters *parameters;
@property (nonatomic, readonly) NSString *originalBackEndDeviceId;
@property (nonatomic, readonly) NSData *originalApnsDeviceToken;
@property (nonatomic, readonly) NSData *updatedApnsDeviceToken;
@property (nonatomic, readonly) NSString *originalReleaseUuid;
@property (nonatomic, readonly) NSString *originalReleaseSecret;
@property (nonatomic, readonly) NSString *originalDeviceAlias;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) BOOL didStartRegistration;
@property (nonatomic, readonly) BOOL didStartAPNSRegistration;
@property (nonatomic, readonly) BOOL didFinishAPNSRegistration;
@property (nonatomic, readonly) BOOL didAPNSRegistrationSucceed;
@property (nonatomic, readonly) BOOL didStartBackendUnregistration;
@property (nonatomic, readonly) BOOL didFinishBackendUnregistration;
@property (nonatomic, readonly) BOOL didStartBackendRegistration;
@property (nonatomic, readonly) BOOL didFinishBackendRegistration;
@property (nonatomic, readonly) BOOL didBackendRegistrationSucceed;
@property (nonatomic, readonly) BOOL didBackEndUnregistrationSucceed;
@property (nonatomic, readonly) BOOL didRegistrationSucceed;

- (instancetype) initWithApplication:(UIApplication*)application
         originalApplicationDelegate:(NSObject<UIApplicationDelegate>*)originalApplicationDelegate
                            listener:(id<OmniaPushRegistrationListener>)listener;

- (void) startRegistration:(OmniaPushRegistrationParameters*)parameters;
- (void) apnsRegistrationSucceeded:(NSData*)apnsDeviceToken;
- (void) apnsRegistrationFailed:(NSError*)apnsRegistrationError;
- (void) backendUnregistrationSucceeded;
- (void) backendUnregistrationFailed:(NSError*)error;
- (void) backendRegistrationSucceeded:(OmniaPushBackEndRegistrationResponseData*)responseData;
- (void) backendRegistrationFailed:(NSError*)error;
- (void) registrationSucceeded;
- (void) registrationFailed;

@end
