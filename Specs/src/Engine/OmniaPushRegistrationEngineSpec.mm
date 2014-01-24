#import "OmniaPushRegistrationEngine.h"
#import "OmniaSpecHelper.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaPushRegistrationFailedOperation.h"
#import "OmniaPushPersistentStorage.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushRegistrationEngineSpec)

describe(@"OmniaPushRegistrationEngine", ^{
    
    __block OmniaSpecHelper *helper;

    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupParametersWithNotificationTypes:TEST_NOTIFICATION_TYPES];
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });
    
    context(@"initialization with bad arguments", ^{
        
        afterEach(^{
            helper.registrationEngine should be_nil;
        });

        it(@"should require an application", ^{
            ^{helper.registrationEngine = [[OmniaPushRegistrationEngine alloc] initWithApplication:nil originalApplicationDelegate:helper.applicationDelegate];}
                should raise_exception([NSException class]);
        });
        
        it(@"should require the original application delegate", ^{
            ^{helper.registrationEngine = [[OmniaPushRegistrationEngine alloc] initWithApplication:helper.application originalApplicationDelegate:nil];}
            should raise_exception([NSException class]);
        });
    });
    
    context(@"initialization with good arguments", ^{
       
        beforeEach(^{
            helper.registrationEngine = [[OmniaPushRegistrationEngine alloc] initWithApplication:helper.application originalApplicationDelegate:helper.applicationDelegate];
        });
        
        it(@"should produce a valid instance", ^{
            helper.registrationEngine should_not be_nil;
        });

        it(@"should retain its arguments in properties", ^{
            helper.registrationEngine.application should be_same_instance_as(helper.application);
        });
        
        it(@"should initialize all the state properties to false", ^{
            helper.registrationEngine.didStartRegistration should_not be_truthy;
            helper.registrationEngine.didStartAPNSRegistration should_not be_truthy;
            helper.registrationEngine.didFinishAPNSRegistration should_not be_truthy;
            helper.registrationEngine.didAPNSRegistrationSucceed should_not be_truthy;
            helper.registrationEngine.didAPNSRegistrationFail should_not be_truthy;
            helper.registrationEngine.didStartBackendUnregistration should_not be_truthy;
            helper.registrationEngine.didFinishBackendUnregistration should_not be_truthy;
            helper.registrationEngine.didStartBackendRegistration should_not be_truthy;
            helper.registrationEngine.didFinishBackendRegistration should_not be_truthy;
            helper.registrationEngine.didRegistrationSucceed should_not be_truthy;
            helper.registrationEngine.didRegistrationFail should_not be_truthy;
            helper.registrationEngine.apnsDeviceToken should be_nil;
            helper.registrationEngine.apnsRegistrationError should be_nil;
        });
        
        context(@"when registering", ^{
            
            __block NSError *testError;
            
            beforeEach(^{
                [helper setupQueues];
                [helper setupAppDelegateProxy];
                testError = [NSError errorWithDomain:@"Some dumb error" code:0 userInfo:nil];
            });
            
            it(@"should require parameters", ^{
                ^{[helper.registrationEngine startRegistration:nil];}
                    should raise_exception([NSException class]);
            });
            
            it(@"should have make a registration request with the same notification type", ^{
                [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES];
                [helper setupApplicationDelegateForSuccessfulRegistration];
                
                [helper.registrationEngine startRegistration:helper.params];
                [helper.workerQueue drain];
                
                helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
                helper.applicationDelegate should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
                [helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
                [helper.workerQueue didFinishOperation:[OmniaPushRegistrationCompleteOperation class]] should be_truthy;
                [helper.workerQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should_not be_truthy;
                [helper.storage loadAPNSDeviceToken] should equal(helper.apnsDeviceToken);
                helper.registrationEngine.didStartRegistration should be_truthy;
                helper.registrationEngine.didStartAPNSRegistration should be_truthy;
                helper.registrationEngine.didFinishAPNSRegistration should be_truthy;
                helper.registrationEngine.didAPNSRegistrationSucceed should be_truthy;
                helper.registrationEngine.didAPNSRegistrationFail should_not be_truthy;
                helper.registrationEngine.didRegistrationSucceed should be_truthy;
                helper.registrationEngine.didRegistrationFail should_not be_truthy;
                helper.registrationEngine.apnsDeviceToken should equal(helper.apnsDeviceToken);
                helper.registrationEngine.apnsRegistrationError should be_nil;
            });
            
            it(@"should call didFailToRegisterForRemoteNotificationsWithError on the appDelegate after a failed registration request", ^{
                [helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
                [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
                
                [helper.registrationEngine startRegistration:helper.params];
                [helper.workerQueue drain];
                
                helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
                helper.applicationDelegate should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
                [helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
                [helper.workerQueue didFinishOperation:[OmniaPushRegistrationCompleteOperation class]] should_not be_truthy;
                [helper.workerQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should be_truthy;
                [helper.storage loadAPNSDeviceToken] should be_nil;
                helper.registrationEngine.didStartRegistration should be_truthy;
                helper.registrationEngine.didStartAPNSRegistration should be_truthy;
                helper.registrationEngine.didFinishAPNSRegistration should be_truthy;
                helper.registrationEngine.didAPNSRegistrationSucceed should_not be_truthy;
                helper.registrationEngine.didAPNSRegistrationFail should be_truthy;
                helper.registrationEngine.didRegistrationSucceed should_not be_truthy;
                helper.registrationEngine.didRegistrationFail should be_truthy;
                helper.registrationEngine.apnsDeviceToken should be_nil;
                helper.registrationEngine.apnsRegistrationError should equal(testError);
            });
        });
    });
});

SPEC_END
