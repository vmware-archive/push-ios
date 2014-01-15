#import "OmniaPushSDK.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAppDelegateProxyImpl.h"
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
        [helper setupOperationQueue];
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
        
        it(@"synchronous registration", ^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
            [helper setupApplicationDelegateForSuccessfulRegistration];
            [helper setApplicationInSingleton];
            
            sdk = [OmniaPushSDK registerForRemoteNotificationTypes:testNotificationTypes];
            sdk should_not be_nil;

            [helper.operationQueue drain];
            
            helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
            helper.applicationDelegate should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
            [helper.operationQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
            [helper.operationQueue didFinishOperation:[OmniaPushRegistrationCompleteOperation class]] should be_truthy;
            [helper.operationQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should_not be_truthy;
            //            previousAppDelegate should be_same_instance_as(getApplication().delegate);
        });
//        
//        it(@"asynchronous registration", ^{
//            setupRegistrationRequestForSuccessfulAsynchronousRegistration(getAppDelegateProxy(), REGISTRATION_DELAY_IN_MILLISECONDS);
//            sdk = [OmniaPushSDK registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getSDKRegistrationListener()];
//            sdk should_not be_nil;
//            waitForSDKRegistrationListenerCallback();
//        });
    });

    describe(@"failed registration", ^{

        __block NSError *testError;

        beforeEach(^{
            testError = [NSError errorWithDomain:@"Some boring error" code:0 userInfo:nil];
        });
        
        afterEach(^{
            testError = nil;
        });
        
        it(@"synchronous registration", ^{
            [helper setupApplicationForFailedRegistrationWithNotificationTypes:testNotificationTypes error:testError];
            [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
            [helper setApplicationInSingleton];
            
            sdk = [OmniaPushSDK registerForRemoteNotificationTypes:testNotificationTypes];
            sdk should_not be_nil;
            
            [helper.operationQueue drain];
            
            helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
            helper.applicationDelegate should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
            [helper.operationQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
            [helper.operationQueue didFinishOperation:[OmniaPushRegistrationCompleteOperation class]] should_not be_truthy;
            [helper.operationQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should be_truthy;
            //            previousAppDelegate should be_same_instance_as(getApplication().delegate);
        });

//        it(@"asynchronous registration", ^{
//            setupRegistrationRequestForFailedAsynchronousRegistration(getAppDelegateProxy(), testError, REGISTRATION_DELAY_IN_MILLISECONDS);
//            sdk = [OmniaPushSDK registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getSDKRegistrationListener()];
//            sdk should_not be_nil;
//            waitForSDKRegistrationListenerCallback();
//        });
    });

});

SPEC_END
