//
//  OmniaRegistrationSpecHelper.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-27.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OmniaSpecHelper;

typedef enum RegistrationStateResult : NSUInteger {
    BE_NIL,
    BE_FALSE,
    BE_TRUE
} RegistrationStateResult;

@interface OmniaRegistrationSpecHelper : NSObject

@property (nonatomic) OmniaSpecHelper* helper;
@property (nonatomic) NSMutableArray* applicationMessages;
@property (nonatomic) NSMutableArray* applicationDelegateMessages;

// Helper lifecycle

- (instancetype) initWithSpecHelper:(OmniaSpecHelper*)helper;
- (void) setup;
- (void) reset;

// Test setup helpers

- (void) setupBackEndForSuccessfulRegistration;
- (void) setupBackEndForSuccessfulRegistrationWithNewBackEndDeviceId:(NSString*)newBackEndDeviceId;
- (void) setupBackEndForFailedRegistrationWithError:(NSError*)error;
- (void) setupBackEndForSuccessfulUnregistration;
- (void) setupBackEndForFailedUnregistrationWithError:(NSError*)error;

// Storage helpers

- (void) saveAPNSDeviceToken:(NSData*)apnsDeviceToken;
- (void) saveBackEndDeviceID:(NSString*)backEndDeviceId;
- (void) saveReleaseUuid:(NSString*)releaseUuid;
- (void) saveReleaseSecret:(NSString*)releaseSecret;
- (void) saveDeviceAlias:(NSString*)deviceAlias;
- (NSData*) apnsDeviceToken;
- (NSString*) backEndDeviceID;
- (NSString*) releaseUuid;
- (NSString*) releaseSecret;
- (NSString*) deviceAlias;

// Test running helpers

- (void) startRegistration;

// Verification helpers

- (void) verifyDidStartRegistration:(RegistrationStateResult)didStartRegistration
           didStartAPNSRegistration:(RegistrationStateResult)didStartAPNSRegistration
          didFinishAPNSRegistration:(RegistrationStateResult)didFinishAPNSRegistration
         didAPNSRegistrationSucceed:(RegistrationStateResult)didAPNSRegistrationSucceed
      didStartBackendUnregistration:(RegistrationStateResult)didStartBackendUnregistration
     didFinishBackendUnregistration:(RegistrationStateResult)didFinishBackendUnregistration
    didBackEndUnregistrationSucceed:(RegistrationStateResult)didBackEndUnregistrationSucceed
        didStartBackendRegistration:(RegistrationStateResult)didStartBackendRegistration
       didFinishBackendRegistration:(RegistrationStateResult)didFinishBackendRegistration
      didBackendRegistrationSucceed:(RegistrationStateResult)didBackendRegistrationSucceed
             didRegistrationSucceed:(RegistrationStateResult)didRegistrationSucceed
                        resultError:(NSError*)resultError;

- (void) verifyQueueCompletedOperations:(NSArray*)completedOperations
                 notCompletedOperations:(NSArray*)notCompletedOperations;

- (void) verifyMessages;

@end
