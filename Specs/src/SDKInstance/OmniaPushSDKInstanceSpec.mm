#import "OmniaPushSDKInstance.h"
#import "OmniaPushAPNSRegistrationRequestImpl.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAppDelegateProxyImpl.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define TEST_NOTIFICATION_TYPE UIRemoteNotificationTypeBadge

SPEC_BEGIN(OmniaPushSDKInstanceSpec)

describe(@"OmniaPushSDKInstance", ^{
    
    __block OmniaPushSDKInstance *sdkInstance;
    __block UIApplication *application;
    __block id<UIApplicationDelegate> appDelegate;
    __block id<OmniaPushAPNSRegistrationRequest> registrationRequest;
    __block OmniaPushAppDelegateProxyImpl *appDelegateProxy;
    
    beforeEach(^{
        application = [UIApplication sharedApplication];
        appDelegate = fake_for(@protocol(UIApplicationDelegate));
        registrationRequest = fake_for(@protocol(OmniaPushAPNSRegistrationRequest));
        appDelegateProxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:appDelegate registrationRequest:registrationRequest];
    });
    
    context(@"when initialization arguments are invalid", ^{
       
        it(@"should require an application", ^{
            ^{sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:nil registrationRequest:registrationRequest appDelegateProxy:appDelegateProxy];}
                should raise_exception([NSException class]);
        });
        
        it(@"should require a registration request", ^{
            ^{sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:application registrationRequest:nil appDelegateProxy:appDelegateProxy];}
                should raise_exception([NSException class]);
        });
        
        it(@"should require an app delegate proxy", ^{
            ^{sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:application registrationRequest:registrationRequest appDelegateProxy:nil];}
            should raise_exception([NSException class]);
        });

    });
    
    context(@"when initialization arguments are valid", ^{

        __block NSData *deviceToken;
        __block id<UIApplicationDelegate> previousAppDelegate;

        beforeEach(^{
            previousAppDelegate = application.delegate;
            deviceToken = [@"TEST DEVICE TOKEN" dataUsingEncoding:NSUTF8StringEncoding];
            sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:application registrationRequest:registrationRequest appDelegateProxy:appDelegateProxy];
        });
        
        it(@"should be constructed successfully", ^{
            sdkInstance should_not be_nil;
        });
        
        it(@"should call register on the registrationRequest successfully", ^{
            registrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
                [appDelegateProxy application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
            });
            appDelegate stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken);

            
            [sdkInstance registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE];
            
            
            registrationRequest should have_received("registerForRemoteNotificationTypes:");
            appDelegate should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
        });
        
        afterEach(^{
            previousAppDelegate should be_same_instance_as(application.delegate);
        });
        
    });

});

SPEC_END
