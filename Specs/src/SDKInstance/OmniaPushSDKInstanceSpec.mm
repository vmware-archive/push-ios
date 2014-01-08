#import "OmniaPushSDKInstance.h"
#import "OmniaPushAPNSRegistrationRequestImpl.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaSpecHelper.h"
#import "OmniaPushDebug.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define REGISTRATION_TIMEOUT_IN_MILLISECONDS  1000
#define REGISTRATION_DELAY_IN_MILLISECONDS    1000
#define TEST_NOTIFICATION_TYPE                UIRemoteNotificationTypeBadge

SPEC_BEGIN(OmniaPushSDKInstanceSpec)

describe(@"OmniaPushSDKInstance", ^{
    
    __block OmniaPushSDKInstance *sdkInstance;
    
    beforeEach(^{
        setupOmniaSpecHelper();
        setupAppDelegate();
        setupRegistrationRequest();
        setupAppDelegateProxy();
        setupDispatchQueue();
    });
    
    afterEach(^{
        resetOmniaSpecHelper();
    });
    
    context(@"when initialization arguments are invalid", ^{
        
        afterEach(^{
            sdkInstance should be_nil;
        });
       
        it(@"should require an application", ^{
            ^{sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:nil registrationRequest:getRegistrationRequest() appDelegateProxy:getAppDelegateProxy() queue:getDispatchQueue()];}
                should raise_exception([NSException class]);
        });
        
        it(@"should require a registration request", ^{
            ^{sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:getApplication() registrationRequest:nil appDelegateProxy:getAppDelegateProxy() queue:getDispatchQueue()];}
                should raise_exception([NSException class]);
        });
        
        it(@"should require an app delegate proxy", ^{
            ^{sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:getApplication() registrationRequest:getRegistrationRequest() appDelegateProxy:nil queue:getDispatchQueue()];}
                should raise_exception([NSException class]);
        });
        
        it(@"should require a dispatch queue", ^{
            ^{sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:getApplication() registrationRequest:getRegistrationRequest() appDelegateProxy:getAppDelegateProxy() queue:nil];}
                should raise_exception([NSException class]);
        });

    });
    
    context(@"when initialization arguments are valid", ^{

        __block id<UIApplicationDelegate> previousAppDelegate;

        beforeEach(^{
            previousAppDelegate = getApplication().delegate;
            sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:getApplication() registrationRequest:getRegistrationRequest() appDelegateProxy:getAppDelegateProxy() queue:getDispatchQueue()];
//            spy_on(sdkInstance); -- need to wait for new Cedar release to stabilize using spies in asynchronous methods
        });
        
        afterEach(^{
            previousAppDelegate should be_same_instance_as(getApplication().delegate);
        });
        
        it(@"should be constructed successfully", ^{
            sdkInstance should_not be_nil;
        });
        
        context(@"successful registrations", ^{

            beforeEach(^{
                setupSDKInstanceRegistrationListener();
                setupSDKInstanceRegistrationListenerForSuccessfulRegistration();
                setupAppDelegateForSuccessfulRegistration();
            });

            afterEach(^{
                getAppDelegate() should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
                getRegistrationRequest() should have_received("registerForRemoteNotificationTypes:");
//                sdkInstance should have_received("registrationCompleteForApplication:");
            });
            
            it(@"should handle synchronous responses", ^{
                setupRegistrationRequestForSuccessfulRegistration(getAppDelegateProxy());
                [sdkInstance registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getSDKInstanceRegistrationListener()];
                waitForSDKInstanceRegistrationListenerCallback();
            });
            
            it(@"should handle asynchronous responses", ^{
                setupRegistrationRequestForSuccessfulAsynchronousRegistration(getAppDelegateProxy(), REGISTRATION_DELAY_IN_MILLISECONDS);
                [sdkInstance registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getSDKInstanceRegistrationListener()];
                waitForSDKInstanceRegistrationListenerCallback();
            });
        });
        
        context(@"failed registrations", ^{

            __block NSError *testError;

            beforeEach(^{
                testError = [NSError errorWithDomain:@"Some lame error" code:0 userInfo:nil];
                setupSDKInstanceRegistrationListener();
                setupSDKInstanceRegistrationListenerForFailedRegistration(testError);
                setupAppDelegateForFailedRegistration(testError);
            });
            
            afterEach(^{
                getAppDelegate() should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
                getRegistrationRequest() should have_received("registerForRemoteNotificationTypes:");
//                sdkInstance should have_received("registrationCompleteForApplication:");
            });

            it(@"should handle synchronous responses", ^{
                setupRegistrationRequestForFailedRegistration(getAppDelegateProxy(), testError);
                [sdkInstance registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getSDKInstanceRegistrationListener()];
                waitForSDKInstanceRegistrationListenerCallback();
            });
            
            it(@"should be able to handle failed registrations", ^{
                setupRegistrationRequestForFailedAsynchronousRegistration(getAppDelegateProxy(), testError, REGISTRATION_DELAY_IN_MILLISECONDS);
                [sdkInstance registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getSDKInstanceRegistrationListener()];
                waitForSDKInstanceRegistrationListenerCallback();
            });
        });
        
        context(@"registration timeout", ^{
            
            beforeEach(^{
                setupSDKInstanceRegistrationListener();
                [sdkInstance changeTimeout:REGISTRATION_TIMEOUT_IN_MILLISECONDS];
            });
            
            afterEach(^{
                getRegistrationRequest() should have_received("registerForRemoteNotificationTypes:");
                getSDKInstanceRegistrationListener() should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
                getAppDelegateProxy() should_not have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
                getAppDelegateProxy() should_not have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
                // sdkInstance should have_received("registrationCompleteForApplication:");
            });

//            it(@"timeout with no further registration callbacks", ^{
//                setupSDKInstanceRegistrationListenerForTimeout();
//                setupRegistrationRequestForTimeout(getAppDelegateProxy());
//                [sdkInstance registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getSDKInstanceRegistrationListener()];
//                waitForSDKInstanceRegistrationListenerCallback();
//            });
            
//            it(@"timeout followed by an application success callback", ^{
//                setupSDKInstanceRegistrationListenerForTimeout();
//                setupSDKInstanceRegistrationListenerForSuccessfulRegistration();
//                setupRegistrationRequestForSuccessfulAsynchronousRegistration(getAppDelegateProxy(), REGISTRATION_DELAY_IN_MILLISECONDS + REGISTRATION_TIMEOUT_IN_MILLISECONDS);
//                [sdkInstance registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getSDKInstanceRegistrationListener()];
//                waitForSDKInstanceRegistrationListenerCallback();
////                waitForSDKInstanceRegistrationListenerCallback();
//            });
        });
    });
});

SPEC_END
