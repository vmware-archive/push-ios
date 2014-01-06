#import "OmniaPushSDK.h"
#import "OmniaPushAPNSRegistrationRequest.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;


SPEC_BEGIN(OmniaPushSDKSpec)

describe(@"OmniaPushSDK", ^{

    __block OmniaPushSDK *sdk;

    __block id<UIApplicationDelegate> previousAppDelegate;
    
    __block void (^resetOmniaPushSDK)(void) = ^{
        // The OmniaPushSDK class is a singleton so we need to reset it between each test.
        // Note that the setSharedInstance: class method is only used by tests and is hidden.
        SEL setSharedInstanceSelector = sel_registerName("setSharedInstance:");
        [OmniaPushSDK performSelector:setSharedInstanceSelector withObject:nil];
        sdk = nil;
    };

    beforeEach(^{
        setupOmniaSpecHelper();
        setupAppDelegate();
        setupRegistrationRequest();
        setupAppDelegateProxy();
        setupSDKRegistrationListener();
        previousAppDelegate = getApplication().delegate;
    });
    
    afterEach(^{
        resetOmniaSpecHelper();
        resetOmniaPushSDK();
    });
    
    describe(@"if you try to register", ^{

        it(@"it should succeed", ^{
            setupRegistrationRequestForSuccessfulRegistration(getAppDelegateProxy());
            setupAppDelegateForSuccessfulRegistration();
            setupSDKRegistrationListenerForSuccessfulRegistration();
            
            setRegistrationRequestInSingleton();
            setApplicationInSingleton();
            setAppDelegateProxyInSingleton();
            
            sdk = [OmniaPushSDK registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE listener:getSDKRegistrationListener()];
            
            waitForSDKRegistrationListenerCallback();
            
            getSDKRegistrationListener() should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
            getRegistrationRequest() should have_received("registerForRemoteNotificationTypes:");
            getAppDelegate() should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
            previousAppDelegate should be_same_instance_as(getApplication().delegate);
        });
        
    });
    
});

SPEC_END
