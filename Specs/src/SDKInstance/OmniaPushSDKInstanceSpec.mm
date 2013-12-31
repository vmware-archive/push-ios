#import "OmniaPushSDKInstance.h"
#import "OmniaPushAPNSRegistrationRequestImpl.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define TEST_NOTIFICATION_TYPE UIRemoteNotificationTypeBadge

SPEC_BEGIN(OmniaPushSDKInstanceSpec)

describe(@"OmniaPushSDKInstance", ^{
    
    __block OmniaPushSDKInstance *sdkInstance;
    
    beforeEach(^{
        setupOmniaSpecHelper();
        setupAppDelegate();
        setupRegistrationRequest();
        setupAppDelegateProxy();
    });
    
    afterEach(^{
        resetOmniaSpecHelper();
    });
    
    context(@"when initialization arguments are invalid", ^{
        
        afterEach(^{
            sdkInstance should be_nil;
        });
       
        it(@"should require an application", ^{
            ^{sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:nil registrationRequest:getRegistrationRequest() appDelegateProxy:getAppDelegateProxy()];}
                should raise_exception([NSException class]);
        });
        
        it(@"should require a registration request", ^{
            ^{sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:getApplication() registrationRequest:nil appDelegateProxy:getAppDelegateProxy()];}
                should raise_exception([NSException class]);
        });
        
        it(@"should require an app delegate proxy", ^{
            ^{sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:getApplication() registrationRequest:getRegistrationRequest() appDelegateProxy:nil];}
            should raise_exception([NSException class]);
        });

    });
    
    context(@"when initialization arguments are valid", ^{

        __block id<UIApplicationDelegate> previousAppDelegate;

        beforeEach(^{
            previousAppDelegate = getApplication().delegate;
            sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:getApplication() registrationRequest:getRegistrationRequest() appDelegateProxy:getAppDelegateProxy()];
        });
        
        afterEach(^{
            previousAppDelegate should be_same_instance_as(getApplication().delegate);
        });
        
        it(@"should be constructed successfully", ^{
            sdkInstance should_not be_nil;
        });
        
        it(@"should call register on the registrationRequest successfully", ^{
            setupRegistrationRequestForSuccessfulRegistration(getAppDelegateProxy());
            setupAppDelegateForSuccessfulRegistration();

            [sdkInstance registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE];
            
            getRegistrationRequest() should have_received("registerForRemoteNotificationTypes:");
            getAppDelegate() should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
        });
        
    });

});

SPEC_END
