#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaPushAppDelegateProxyListener.h"
#import "OmniaPushAPNSRegistrationRequest.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define TEST_NOTIFICATION_TYPE UIRemoteNotificationTypeAlert

SPEC_BEGIN(OmniaPushAppDelegateProxyImplSpec)

describe(@"OmniaPushAppDelegateProxyImpl", ^{
    
    __block OmniaPushAppDelegateProxyImpl *proxy;
    __block id<UIApplicationDelegate> appDelegate;
    __block id<OmniaPushAPNSRegistrationRequest> registrationRequest;
    __block id<OmniaPushAppDelegateProxyListener> proxyListener;

    beforeEach(^{
        appDelegate = fake_for(@protocol(UIApplicationDelegate));
        registrationRequest = fake_for(@protocol(OmniaPushAPNSRegistrationRequest));
        proxyListener = fake_for(@protocol(OmniaPushAppDelegateProxyListener));
        spy_on(appDelegate);
        spy_on(registrationRequest);
    });
    
    context(@"when init has invalid arguments", ^{
        
        it(@"should require an app delegate", ^{
            ^{proxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:nil registrationRequest:registrationRequest];}
                should raise_exception([NSException class]);
        });

        it(@"should require a registration request object", ^{
            ^{proxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:appDelegate registrationRequest:nil];}
                should raise_exception([NSException class]);
        });
    });
    
    context(@"when it has valid arguments", ^{
        
        __block NSData *deviceToken;
        __block UIApplication *testApplication;
        __block NSError *testError;
        
        beforeEach(^{
            proxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:appDelegate registrationRequest:registrationRequest];
            deviceToken = [@"TEST DEVICE TOKEN" dataUsingEncoding:NSUTF8StringEncoding];
            testApplication = [UIApplication sharedApplication];
            testError = [NSError errorWithDomain:@"Some dumb error" code:0 userInfo:nil];
        });
        
        it(@"should have make a registration request with the same notification type", ^{
            registrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE);
            proxyListener stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(testApplication, deviceToken);
            
            [proxy registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:proxyListener];
            
            registrationRequest should have_received("registerForRemoteNotificationTypes:");
        });
        
        it(@"should call didRegisterForRemoteNotifications on the appDelegate after a successful registration request", ^{
            proxyListener stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(testApplication, deviceToken);
            registrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
                [proxy application:testApplication didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
            });
            appDelegate stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(testApplication, deviceToken);
            [proxy registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:proxyListener];
            appDelegate should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
            proxyListener should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
        });

        it(@"should call didFailToRegisterForRemoteNotificationsWithError on the appDelegate after a failed registration request", ^{
            proxyListener stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(testApplication, testError);
            registrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
                [proxy application:testApplication didFailToRegisterForRemoteNotificationsWithError:testError];
            });
            appDelegate stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(testApplication, testError);
            [proxy registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:proxyListener];
            appDelegate should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
            proxyListener should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
        });

        
    });
});

SPEC_END
