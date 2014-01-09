#import "OmniaPushSDK.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaSpecHelper.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define REGISTRATION_DELAY_IN_MILLISECONDS    1000ull

SPEC_BEGIN(OmniaPushSDKSpec)

describe(@"OmniaPushSDK", ^{
//
//    __block OmniaPushSDK *sdk;
//
//    __block id<UIApplicationDelegate> previousAppDelegate;
//    
//    __block void (^resetOmniaPushSDK)(void) = ^{
//        // The OmniaPushSDK class is a singleton so we need to reset it between each test.
//        // Note that the setSharedInstance: class method is only used by tests and is hidden.
//        SEL setSharedInstanceSelector = sel_registerName("setSharedInstance:");
//        [OmniaPushSDK performSelector:setSharedInstanceSelector withObject:nil];
//        sdk = nil;
//    };
//
//    beforeEach(^{
//        setupOmniaSpecHelper();
//        setupAppDelegate();
//        setupRegistrationRequest();
//        setupAppDelegateProxy();
//        setupSDKRegistrationListener();
//        previousAppDelegate = getApplication().delegate;
//    });
//    
//    afterEach(^{
//        resetOmniaSpecHelper();
//        resetOmniaPushSDK();
//    });
//    
//    describe(@"successful registration", ^{
//        
//        beforeEach(^{
//            setupAppDelegateForSuccessfulRegistration();
//            setupSDKRegistrationListenerForSuccessfulRegistration();
//            setRegistrationRequestInSingleton();
//            setApplicationInSingleton();
//            setAppDelegateProxyInSingleton();
//        });
//        
//        afterEach(^{
//            getSDKRegistrationListener() should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
//            getRegistrationRequest() should have_received("registerForRemoteNotificationTypes:");
//            getAppDelegate() should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
//            previousAppDelegate should be_same_instance_as(getApplication().delegate);
//        });
//
//        it(@"synchronous registration", ^{
//            setupRegistrationRequestForSuccessfulRegistration(getAppDelegateProxy());
//            sdk = [OmniaPushSDK registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getSDKRegistrationListener()];
//            sdk should_not be_nil;
//            waitForSDKRegistrationListenerCallback();
//        });
//        
//        it(@"asynchronous registration", ^{
//            setupRegistrationRequestForSuccessfulAsynchronousRegistration(getAppDelegateProxy(), REGISTRATION_DELAY_IN_MILLISECONDS);
//            sdk = [OmniaPushSDK registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getSDKRegistrationListener()];
//            sdk should_not be_nil;
//            waitForSDKRegistrationListenerCallback();
//        });
//    });
//    
//    describe(@"failed registration", ^{
//
//        __block NSError *testError;
//
//        beforeEach(^{
//            testError = [NSError errorWithDomain:@"Some boring error" code:0 userInfo:nil];
//            setupAppDelegateForFailedRegistration(testError);
//            setupSDKRegistrationListenerForFailedRegistration(testError);
//            setRegistrationRequestInSingleton();
//            setApplicationInSingleton();
//            setAppDelegateProxyInSingleton();
//        });
//        
//        afterEach(^{
//            getSDKRegistrationListener() should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
//            getRegistrationRequest() should have_received("registerForRemoteNotificationTypes:");
//            getAppDelegate() should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
//            previousAppDelegate should be_same_instance_as(getApplication().delegate);
//        });
//        
//        it(@"synchronous registration", ^{
//            setupRegistrationRequestForFailedRegistration(getAppDelegateProxy(), testError);
//            sdk = [OmniaPushSDK registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getSDKRegistrationListener()];
//            sdk should_not be_nil;
//            waitForSDKRegistrationListenerCallback();
//        });
//        
//        it(@"asynchronous registration", ^{
//            setupRegistrationRequestForFailedAsynchronousRegistration(getAppDelegateProxy(), testError, REGISTRATION_DELAY_IN_MILLISECONDS);
//            sdk = [OmniaPushSDK registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getSDKRegistrationListener()];
//            sdk should_not be_nil;
//            waitForSDKRegistrationListenerCallback();
//        });
//    });
//    
});

SPEC_END
