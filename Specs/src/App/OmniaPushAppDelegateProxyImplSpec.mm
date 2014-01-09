#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaPushRegistrationListener.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushAppDelegateProxyImplSpec)

describe(@"OmniaPushAppDelegateProxyImpl", ^{
    
    __block OmniaPushAppDelegateProxyImpl *proxy;
    __block UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeAlert;

    beforeEach(^{
        setupOmniaSpecHelper();
        setupApplication();
        setupApplicationDelegate();
        setupRegistrationRequestOperation(notificationTypes);
    });
    
    afterEach(^{
        resetOmniaSpecHelper();
    });
    
    context(@"when init has invalid arguments", ^{
        
        afterEach(^{
            proxy should be_nil;
        });
        
        it(@"should require an app delegate", ^{
            ^{proxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:nil registrationRequest:getRegistrationRequestOperation()];}
                should raise_exception([NSException class]);
        });

        it(@"should require a registration request object", ^{
            ^{proxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:getApplicationDelegate() registrationRequest:nil];}
                should raise_exception([NSException class]);
        });
    });
    
    context(@"when it has valid arguments", ^{
        
        __block NSError *testError;
        
        beforeEach(^{
            testError = [NSError errorWithDomain:@"Some dumb error" code:0 userInfo:nil];
            proxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:getApplicationDelegate() registrationRequest:getRegistrationRequestOperation()];
        });
        
        it(@"should be constructed successfully", ^{
            proxy should_not be_nil;
        });
    
        context(@"when registering", ^{
            
            afterEach(^{
            });
            
//            it(@"should have make a registration request with the same notification type", ^{
//                setupAppDelegateForSuccessfulRegistration();
//                
//                [proxy registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getAppDelegateProxyRegistrationListener()];
//                
//                getAppDelegate() should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
//            });
            
//            it(@"should call didFailToRegisterForRemoteNotificationsWithError on the appDelegate after a failed registration request", ^{
//                setupRegistrationRequestForFailedRegistration(proxy, testError);
//                setupAppDelegateProxyRegistrationListenerForFailedRegistration(testError);
//                setupAppDelegateForFailedRegistration(testError);
//                
//                [proxy registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getAppDelegateProxyRegistrationListener()];
//                
//                getAppDelegate() should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
//                getAppDelegateProxyRegistrationListener() should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
//            });
        });
    });
});

SPEC_END
