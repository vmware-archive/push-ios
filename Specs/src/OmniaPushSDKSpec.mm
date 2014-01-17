#import "OmniaPushSDK.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaSpecHelper.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaPushRegistrationFailedOperation.h"
#import "OmniaFakeOperationQueue.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define REGISTRATION_DELAY_IN_MILLISECONDS    1000ull

SPEC_BEGIN(OmniaPushSDKSpec)

describe(@"OmniaPushSDK", ^{
    
    __block OmniaPushSDK *sdk;
    __block OmniaSpecHelper *helper = nil;
    __block UIRemoteNotificationType testNotificationTypes = UIRemoteNotificationTypeAlert;
    __block id<UIApplicationDelegate> previousAppDelegate;
    
    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupRegistrationRequestOperationWithNotificationTypes:testNotificationTypes];
        [helper setupQueues];
        previousAppDelegate = helper.applicationDelegate;
    });
    
    afterEach(^{
        previousAppDelegate = nil;
        [helper resetSingleton];
        [helper reset];
        helper = nil;
        sdk = nil;
    });

    describe(@"successful registration", ^{
        
        beforeEach(^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
            [helper setupApplicationDelegateForSuccessfulRegistration];
            [helper setApplicationInSingleton];

            sdk = [OmniaPushSDK registerForRemoteNotificationTypes:testNotificationTypes];
            sdk should_not be_nil;
            
            [helper.workerQueue drain];
        });
        
        it(@"should handle successful registrations from APNS", ^{
            helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
            helper.applicationDelegate should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
            [helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationCompleteOperation class]] should be_truthy;
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should_not be_truthy;
        });
        
        it(@"should restore the application delegate after tearing down", ^{
            SEL teardownSelector = sel_registerName("teardown");
            [OmniaPushSDK performSelector:teardownSelector];
            UIApplication *app = (UIApplication*)(helper.application);
            app.delegate should be_same_instance_as(previousAppDelegate);
        });
    });

    describe(@"failed registration", ^{

        __block NSError *testError;

        beforeEach(^{
            testError = [NSError errorWithDomain:@"Some boring error" code:0 userInfo:nil];
            [helper setupApplicationForFailedRegistrationWithNotificationTypes:testNotificationTypes error:testError];
            [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
            [helper setApplicationInSingleton];
            
            sdk = [OmniaPushSDK registerForRemoteNotificationTypes:testNotificationTypes];
            sdk should_not be_nil;
            
            [helper.workerQueue drain];
        });
        
        afterEach(^{
            testError = nil;
        });
        
        it(@"should handle registration failures from APNS", ^{
            helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
            helper.applicationDelegate should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
            [helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationCompleteOperation class]] should_not be_truthy;
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should be_truthy;
        });
        
        it(@"should restore the application delegate after tearing down", ^{
            SEL teardownSelector = sel_registerName("teardown");
            [OmniaPushSDK performSelector:teardownSelector];
            UIApplication *app = (UIApplication*)(helper.application);
            app.delegate should be_same_instance_as(previousAppDelegate);
        });
    });
});

SPEC_END
