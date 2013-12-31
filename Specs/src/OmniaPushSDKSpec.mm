#import "OmniaPushSDK.h"
#import "OmniaPushAPNSRegistrationRequest.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAppDelegateProxyImpl.h"

#define TEST_NOTIFICATION_TYPE UIRemoteNotificationTypeBadge

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

void setFakeRegistrationRequest(NSObject<OmniaPushAPNSRegistrationRequest> *registrationRequest) {
    SEL setupRegistrationRequestSelector = sel_registerName("setupRegistrationRequest:");
    [OmniaPushSDK performSelector:setupRegistrationRequestSelector withObject:registrationRequest];
}

void setFakeApplication(UIApplication *application) {
    SEL setupApplicationSelector = sel_registerName("setupApplication:");
    [OmniaPushSDK performSelector:setupApplicationSelector withObject:application];
}

void setFakeAppDelegateProxy(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy) {
    SEL setupAppDelegateProxySelector = sel_registerName("setupAppDelegateProxy:");
    [OmniaPushSDK performSelector:setupAppDelegateProxySelector withObject:appDelegateProxy];
}

SPEC_BEGIN(OmniaPushSDKSpec)

describe(@"OmniaPushSDK", ^{

    __block OmniaPushSDK *sdk;
    __block UIApplication *application;
    __block id<UIApplicationDelegate> appDelegate;
    __block id<OmniaPushAPNSRegistrationRequest> registrationRequest;
    __block OmniaPushAppDelegateProxyImpl *appDelegateProxy;

    __block NSData *deviceToken;
    __block id<UIApplicationDelegate> previousAppDelegate;

    beforeEach(^{
        application = [UIApplication sharedApplication];
        appDelegate = fake_for(@protocol(UIApplicationDelegate));
        registrationRequest = fake_for(@protocol(OmniaPushAPNSRegistrationRequest));
        appDelegateProxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:appDelegate registrationRequest:registrationRequest];
        
        previousAppDelegate = application.delegate;
        deviceToken = [@"TEST DEVICE TOKEN" dataUsingEncoding:NSUTF8StringEncoding];
    });
    
    describe(@"if you try to register", ^{

        it(@"it should succeed", ^{
            registrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
                [appDelegateProxy application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
            });
            appDelegate stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken);
            setFakeRegistrationRequest(registrationRequest);
            setFakeApplication(application);
            setFakeAppDelegateProxy(appDelegateProxy);
            
            sdk = [OmniaPushSDK registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge];
            
            
            registrationRequest should have_received("registerForRemoteNotificationTypes:");
            appDelegate should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
            previousAppDelegate should be_same_instance_as(application.delegate);
        });
        
    });
    
    beforeEach(^{
        // TODO - wait for any active intialization to complete before ending test

        // The OmniaPushSDK class is a singleton so we need to reset it between each test.
        // Note that the setSharedInstance: class method is only used by tests and is hidden.
        SEL setSharedInstanceSelector = sel_registerName("setSharedInstance:");
        [OmniaPushSDK performSelector:setSharedInstanceSelector withObject:nil];
        sdk = nil;
    });
    
    afterEach(^{
        // TODO - wait for any active intialization to complete before ending test
        
        // The OmniaPushSDK class is a singleton so we need to reset it between each test.
        // Note that the setSharedInstance: class method is only used by tests and is hidden.
        SEL setSharedInstanceSelector = sel_registerName("setSharedInstance:");
        [OmniaPushSDK performSelector:setSharedInstanceSelector withObject:nil];
        sdk = nil;
    });
});

SPEC_END
