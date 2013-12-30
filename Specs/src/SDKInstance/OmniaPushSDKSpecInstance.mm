#import "OmniaPushSDKInstance.h"
#import "OmniaPushAPNSRegistrationRequestImpl.h"
#import "OmniaPushAppDelegateProxy.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define TEST_NOTIFICATION_TYPE UIRemoteNotificationTypeBadge

SPEC_BEGIN(OmniaPushSDKInstanceSpec)

describe(@"OmniaPushSDKInstance", ^{
    
    __block OmniaPushSDKInstance *sdkInstance;
    __block UIApplication *application;
    __block id<OmniaPushAPNSRegistrationRequest> registrationRequest;
    __block id<OmniaPushAppDelegateProxy> appDelegateProxy;
    
    beforeEach(^{
        application = [UIApplication sharedApplication];
        registrationRequest = fake_for(@protocol(OmniaPushAPNSRegistrationRequest));
        appDelegateProxy = fake_for(@protocol(OmniaPushAppDelegateProxy));
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
        __block id<UIApplicationDelegate> previousApplicationDelegate;

        beforeEach(^{
            previousApplicationDelegate = application.delegate;
            deviceToken = [@"TEST DEVICE TOKEN" dataUsingEncoding:NSUTF8StringEncoding];
            sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:application registrationRequest:registrationRequest appDelegateProxy:appDelegateProxy];
        });
        
        it(@"should be constructed successfully", ^{
            sdkInstance should_not be_nil;
        });
        
        it(@"should call register on the registrationRequest successfully", ^{
            appDelegateProxy stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
                [registrationRequest registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE];
            });
            registrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
                [appDelegateProxy application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
            });
            appDelegateProxy stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken);

            
            [sdkInstance registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE];
            
            
            appDelegateProxy should have_received("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE);
            registrationRequest should have_received("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE);
            appDelegateProxy should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken);
        });
        
        afterEach(^{
//            previousApplicationDelegate should be_same_instance_as(application.delegate);
        });
        
    });

});

SPEC_END
