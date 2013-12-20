#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaPushAPNSRegistrationRequest.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define TEST_NOTIFICATION_TYPE UIRemoteNotificationTypeAlert

SPEC_BEGIN(OmniaPushAppDelegateProxyImplSpec)

describe(@"OmniaPushAppDelegateProxyImpl", ^{
    
    __block OmniaPushAppDelegateProxyImpl *proxy;
    __block id<CedarDouble> fakeAppDelegate;
    __block id<CedarDouble> fakeRegistrationRequest;

    beforeEach(^{
        fakeAppDelegate = fake_for(@protocol(UIApplicationDelegate));
        fakeRegistrationRequest = fake_for(@protocol(OmniaPushAPNSRegistrationRequest));
        spy_on(fakeAppDelegate);
        spy_on(fakeRegistrationRequest);
    });
    
    context(@"when init has invalid arguments", ^{
        
        it(@"should require an app delegate", ^{
            ^{proxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:nil registrationRequest:(id<OmniaPushAPNSRegistrationRequest>)fakeRegistrationRequest];}
                should raise_exception([NSException class]);
        });

        it(@"should require a registration request object", ^{
            ^{proxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:(id<UIApplicationDelegate>)fakeAppDelegate registrationRequest:nil];}
                should raise_exception([NSException class]);
        });
        
    });
    
    context(@"when it has valid arguments", ^{
        
        __block NSData *deviceToken;
        __block UIApplication *testApplication;
        __block NSError *testError;
        
        beforeEach(^{
            proxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:(id<UIApplicationDelegate>)fakeAppDelegate registrationRequest:(id<OmniaPushAPNSRegistrationRequest>)fakeRegistrationRequest];
            deviceToken = [@"TEST DEVICE TOKEN" dataUsingEncoding:NSUTF8StringEncoding];
            testApplication = [UIApplication sharedApplication];
            testError = [NSError errorWithDomain:@"Some dumb error" code:0 userInfo:nil];
        });
        
        it(@"should have make a registration request with the same notification type", ^{
            fakeRegistrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE);
            [proxy registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE];
            fakeRegistrationRequest should have_received("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE);
        });
        
        it(@"should call didRegisterForRemoteNotifications on the appDelegate after a successful registration request", ^{
            fakeRegistrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
                [proxy application:testApplication didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
            });
            fakeAppDelegate stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(testApplication, deviceToken);
            [proxy registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE];
            fakeAppDelegate should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
        });

        it(@"should call didFailToRegisterForRemoteNotificationsWithError on the appDelegate after a failed registration request", ^{
            fakeRegistrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
                [proxy application:testApplication didFailToRegisterForRemoteNotificationsWithError:testError];
            });
            fakeAppDelegate stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(testApplication, testError);
            [proxy registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE];
            fakeAppDelegate should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
        });

        
    });
});

SPEC_END
