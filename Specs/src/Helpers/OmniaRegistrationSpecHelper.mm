//
//  OmniaRegistrationSpecHelper.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-27.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaRegistrationSpecHelper.h"
#import "OmniaPushRegistrationEngine.h"
#import "OmniaSpecHelper.h"
#import "OmniaPushPersistentStorage.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define verifyState(stateField, stateResult) \
    if ((stateResult) == BE_TRUE) { \
        (stateField) should be_truthy; \
    } else if ((stateResult) == BE_FALSE) { \
        (stateField) should_not be_truthy; \
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
    [self.helper setupApplication];
    [self.helper setupApplicationDelegate];
    [self.helper setupParametersWithNotificationTypes:TEST_NOTIFICATION_TYPES];
}

- (void) reset
{
    if (self.helper) {
        [self.helper reset];
        self.helper = nil;
    }
}

- (void) verifyDidStartRegistration:(RegistrationStateResult)stateDidStartRegistration
           didStartAPNSRegistration:(RegistrationStateResult)stateDidStartAPNSRegistration
          didFinishAPNSRegistration:(RegistrationStateResult)stateDidFinishAPNSRegistration
         didAPNSRegistrationSucceed:(RegistrationStateResult)stateDidAPNSRegistrationSucceed
            didAPNSRegistrationFail:(RegistrationStateResult)stateDidAPNSRegistrationFail
      didStartBackendUnregistration:(RegistrationStateResult)stateDidStartBackendUnregistration
     didFinishBackendUnregistration:(RegistrationStateResult)stateDidFinishBackendUnregistration
        didStartBackendRegistration:(RegistrationStateResult)stateDidStartBackendRegistration
       didFinishBackendRegistration:(RegistrationStateResult)stateDidFinishBackendRegistration
             didRegistrationSucceed:(RegistrationStateResult)stateDidRegistrationSucceed
                didRegistrationFail:(RegistrationStateResult)stateDidRegistrationFail
              resultAPNSDeviceToken:(NSData*)resultApnsDeviceToken
        resultAPNSRegistrationError:(NSError*)resultApnsRegistrationError
{
    verifyState(self.helper.registrationEngine.didStartRegistration, stateDidStartRegistration);
    verifyState(self.helper.registrationEngine.didStartAPNSRegistration, stateDidStartAPNSRegistration);
    verifyState(self.helper.registrationEngine.didFinishAPNSRegistration, stateDidFinishAPNSRegistration);
    verifyState(self.helper.registrationEngine.didAPNSRegistrationSucceed, stateDidAPNSRegistrationSucceed);
    verifyState(self.helper.registrationEngine.didAPNSRegistrationFail, stateDidAPNSRegistrationFail);
    verifyState(self.helper.registrationEngine.didStartBackendUnregistration, stateDidStartBackendUnregistration);
    verifyState(self.helper.registrationEngine.didFinishBackendUnregistration, stateDidFinishBackendUnregistration);
    verifyState(self.helper.registrationEngine.didStartBackendRegistration, stateDidStartBackendRegistration);
    verifyState(self.helper.registrationEngine.didFinishBackendRegistration, stateDidFinishBackendRegistration);
    verifyState(self.helper.registrationEngine.didRegistrationSucceed, stateDidRegistrationSucceed);
    verifyState(self.helper.registrationEngine.didRegistrationFail, stateDidRegistrationFail);
    verifyValue(self.helper.registrationEngine.apnsDeviceToken, resultApnsDeviceToken);
    verifyValue(self.helper.registrationEngine.apnsRegistrationError, resultApnsRegistrationError);
    verifyValue([self.helper.storage loadAPNSDeviceToken], resultApnsDeviceToken);
}

@end
