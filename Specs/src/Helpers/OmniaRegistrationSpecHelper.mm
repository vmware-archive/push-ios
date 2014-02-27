//
//  OmniaRegistrationSpecHelper.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-27.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaRegistrationSpecHelper.h"
#import "OmniaPushRegistrationEngine.h"
#import "OmniaSpecHelper.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushBackEndRegistrationRequest.h"
#import "OmniaPushBackEndRegistrationRequestProvider.h"
#import "OmniaPushBackEndUnregistrationRequestProvider.h"
#import "OmniaPushFakeBackEndRegistrationRequest.h"
#import "OmniaPushFakeBackEndUnregistrationRequest.h"
#import "OmniaPushBackEndRegistrationResponseData.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define verifyState(stateField, stateResult) \
    if ((stateResult) == BE_TRUE) { \
        (stateField) should be_truthy; \
    } else if ((stateResult) == BE_FALSE) { \
        (stateField) should be_falsy; \
    } else if ((stateResult) == BE_NIL) { \
        (stateField) should be_nil; \
    }

#define verifyValue(stateField, expectedValue) \
    if ((expectedValue) == nil) { \
        (stateField) should be_nil; \
    } else { \
        (stateField) should equal((expectedValue)); \
    }

@implementation OmniaRegistrationSpecHelper

#pragma mark - Helper lifecycle

- (instancetype) initWithSpecHelper:(OmniaSpecHelper*)helper
{
    self = [super init];
    if (self) {
        self.helper = helper;
    }
    return self;
}

- (void) setup
{
    self.applicationMessages = [NSMutableArray array];
    self.applicationDelegateMessages = [NSMutableArray array];
    [self.helper setupApplication];
    [self.helper setupApplicationDelegate];
    [self.helper setupParametersWithNotificationTypes:TEST_NOTIFICATION_TYPES];
    [self.applicationMessages addObject:@"registerForRemoteNotificationTypes:"];
}

- (void) reset
{
    if (self.helper) {
        [self.helper reset];
        self.helper = nil;
        self.applicationMessages = nil;
        self.applicationDelegateMessages = nil;
        [OmniaPushBackEndRegistrationRequestProvider setRequest:nil];
        [OmniaPushBackEndUnregistrationRequestProvider setRequest:nil];
    }
}

#pragma mark - Test setup helpers

- (OmniaPushBackEndRegistrationResponseData*) getBackEndRegistrationResponseDataForBackEndDeviceId:(NSString*)backEndDeviceId
{
    OmniaPushBackEndRegistrationResponseData *responseData = [[OmniaPushBackEndRegistrationResponseData alloc] init];
    responseData.deviceUuid = backEndDeviceId;
    return responseData;
}

- (void) setupBackEndForSuccessfulRegistration
{
    [self setupBackEndForSuccessfulRegistrationWithNewBackEndDeviceId:self.helper.backEndDeviceId];
}

- (void) setupBackEndForSuccessfulRegistrationWithNewBackEndDeviceId:(NSString*)newBackEndDeviceId
{
    OmniaPushFakeBackEndRegistrationRequest *backEndRegistrationRequest = [[OmniaPushFakeBackEndRegistrationRequest alloc] init];
    [backEndRegistrationRequest setupForSuccessWithResponseData:[self getBackEndRegistrationResponseDataForBackEndDeviceId:newBackEndDeviceId]];
    [OmniaPushBackEndRegistrationRequestProvider setRequest:backEndRegistrationRequest];
}

- (void) setupBackEndForFailedRegistrationWithError:(NSError*)error
{
    OmniaPushFakeBackEndRegistrationRequest *backEndRegistrationRequest = [[OmniaPushFakeBackEndRegistrationRequest alloc] init];
    [backEndRegistrationRequest setupForFailureWithError:error];
    [OmniaPushBackEndRegistrationRequestProvider setRequest:backEndRegistrationRequest];
}

- (void) setupBackEndForSuccessfulUnregistration
{
    OmniaPushFakeBackEndUnregistrationRequest *backEndUnregistrationRequest = [[OmniaPushFakeBackEndUnregistrationRequest alloc] init];
    [backEndUnregistrationRequest setupForSuccess];
    [OmniaPushBackEndUnregistrationRequestProvider setRequest:backEndUnregistrationRequest];
}

- (void) setupBackEndForFailedUnregistrationWithError:(NSError*)error
{
    OmniaPushFakeBackEndUnregistrationRequest *backEndUnregistrationRequest = [[OmniaPushFakeBackEndUnregistrationRequest alloc] init];
    [backEndUnregistrationRequest setupForFailureWithError:error];
    [OmniaPushBackEndUnregistrationRequestProvider setRequest:backEndUnregistrationRequest];
}

#pragma mark - Storage helpers

- (void) saveAPNSDeviceToken:(NSData*)apnsDeviceToken
{
    [self.helper.storage saveAPNSDeviceToken:apnsDeviceToken];
}

- (NSData*) apnsDeviceToken
{
    return [self.helper.storage loadAPNSDeviceToken];
}

- (void) saveBackEndDeviceID:(NSString*)backEndDeviceId
{
    [self.helper.storage saveBackEndDeviceID:backEndDeviceId];
}

- (NSString*) backEndDeviceID
{
    return [self.helper.storage loadBackEndDeviceID];
}

- (void) saveReleaseUuid:(NSString*)releaseUuid
{
    [self.helper.storage saveReleaseUuid:releaseUuid];
}

- (NSString*) releaseUuid
{
    return [self.helper.storage loadReleaseUuid];
}

- (void) saveReleaseSecret:(NSString*)releaseSecret
{
    [self.helper.storage saveReleaseSecret:releaseSecret];
}

- (NSString*) releaseSecret
{
    return [self.helper.storage loadReleaseSecret];
}

- (void) saveDeviceAlias:(NSString*)deviceAlias
{
    [self.helper.storage saveDeviceAlias:deviceAlias];
}

- (NSString*) deviceAlias
{
    return [self.helper.storage loadDeviceAlias];
}

#pragma mark - Test running helpers

- (void) startRegistration
{
    [self.helper.registrationEngine startRegistration:self.helper.params];
    [self.helper.workerQueue drain];
}

#pragma mark - Verification helpers

- (void) verifyDidStartRegistration:(RegistrationStateResult)stateDidStartRegistration
           didStartAPNSRegistration:(RegistrationStateResult)stateDidStartAPNSRegistration
          didFinishAPNSRegistration:(RegistrationStateResult)stateDidFinishAPNSRegistration
         didAPNSRegistrationSucceed:(RegistrationStateResult)stateDidAPNSRegistrationSucceed
      didStartBackendUnregistration:(RegistrationStateResult)stateDidStartBackendUnregistration
     didFinishBackendUnregistration:(RegistrationStateResult)stateDidFinishBackendUnregistration
    didBackEndUnregistrationSucceed:(RegistrationStateResult)stateDidBackEndUnregistrationSucceed
        didStartBackendRegistration:(RegistrationStateResult)stateDidStartBackendRegistration
       didFinishBackendRegistration:(RegistrationStateResult)stateDidFinishBackendRegistration
      didBackendRegistrationSucceed:(RegistrationStateResult)stateDidBackendRegistrationSucceed
             didRegistrationSucceed:(RegistrationStateResult)stateDidRegistrationSucceed
                        resultError:(NSError*)resultError
{
    verifyState(self.helper.registrationEngine.didStartRegistration, stateDidStartRegistration);
    verifyState(self.helper.registrationEngine.didStartAPNSRegistration, stateDidStartAPNSRegistration);
    verifyState(self.helper.registrationEngine.didFinishAPNSRegistration, stateDidFinishAPNSRegistration);
    verifyState(self.helper.registrationEngine.didAPNSRegistrationSucceed, stateDidAPNSRegistrationSucceed);
    verifyState(self.helper.registrationEngine.didStartBackendUnregistration, stateDidStartBackendUnregistration);
    verifyState(self.helper.registrationEngine.didFinishBackendUnregistration, stateDidFinishBackendUnregistration);
    verifyState(self.helper.registrationEngine.didBackEndUnregistrationSucceed, stateDidBackEndUnregistrationSucceed);
    verifyState(self.helper.registrationEngine.didStartBackendRegistration, stateDidStartBackendRegistration);
    verifyState(self.helper.registrationEngine.didFinishBackendRegistration, stateDidFinishBackendRegistration);
    verifyState(self.helper.registrationEngine.didBackendRegistrationSucceed, stateDidBackendRegistrationSucceed);
    verifyState(self.helper.registrationEngine.didRegistrationSucceed, stateDidRegistrationSucceed);
    verifyValue(self.helper.registrationEngine.error, resultError);
}

- (void) verifyQueueCompletedOperations:(NSArray*)completedOperations
                 notCompletedOperations:(NSArray*)notCompletedOperations;
{
    for (Class classOfOperation : completedOperations) {
        [self.helper.workerQueue didFinishOperation:classOfOperation] should be_truthy;
    }
    for (Class classOfOperation : notCompletedOperations) {
        [self.helper.workerQueue didFinishOperation:classOfOperation] should be_falsy;
    }
}

- (void) verifyMessages
{
    for (NSString *message in self.applicationMessages) {
        self.helper.application should have_received([message cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    for (NSString *message in self.applicationDelegateMessages) {
        self.helper.applicationDelegate should have_received([message cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}


@end
