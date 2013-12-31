#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaPushAppDelegateProxyListener.h"
#import "OmniaPushAPNSRegistrationRequest.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushAppDelegateProxyImplSpec)

describe(@"OmniaPushAppDelegateProxyImpl", ^{
    
    __block OmniaPushAppDelegateProxyImpl *proxy;

    beforeEach(^{
        setupOmniaSpecHelper();
        setupAppDelegate();
        setupRegistrationRequest();
        setupAppDelegateProxyListener();
    });
    
    afterEach(^{
        resetOmniaSpecHelper();
    });
    
    context(@"when init has invalid arguments", ^{
        
        afterEach(^{
            proxy should be_nil;
        });
        
        it(@"should require an app delegate", ^{
            ^{proxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:nil registrationRequest:getRegistrationRequest()];}
                should raise_exception([NSException class]);
        });

        it(@"should require a registration request object", ^{
            ^{proxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:getAppDelegate() registrationRequest:nil];}
                should raise_exception([NSException class]);
        });
    });
    
    context(@"when it has valid arguments", ^{
        
        __block NSError *testError;
        
        beforeEach(^{
            testError = [NSError errorWithDomain:@"Some dumb error" code:0 userInfo:nil];
            proxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:getAppDelegate() registrationRequest:getRegistrationRequest()];
        });
        
        it(@"should be constructed successfully", ^{
            proxy should_not be_nil;
        });
        
        it(@"should have make a registration request with the same notification type", ^{
            setupAppDelegateProxyListenerForSuccessfulRegistration();
            setupRegistrationRequestForSuccessfulRegistration(proxy);
            setupAppDelegateForSuccessfulRegistration();
            
            [proxy registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getAppDelegateProxyListener()];
            
            getRegistrationRequest() should have_received("registerForRemoteNotificationTypes:");
            getAppDelegate() should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
            getAppDelegateProxyListener() should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
        });

        it(@"should call didFailToRegisterForRemoteNotificationsWithError on the appDelegate after a failed registration request", ^{
            setupRegistrationRequestForFailedRegistration(proxy, testError);
            setupAppDelegateProxyListenerForFailedRegistration(testError);
            setupAppDelegateForFailedRegistration(testError);
            
            [proxy registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getAppDelegateProxyListener()];
            
            getRegistrationRequest() should have_received("registerForRemoteNotificationTypes:");
            getAppDelegate() should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
            getAppDelegateProxyListener() should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
        });
    });
});

SPEC_END
