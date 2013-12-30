#import "OmniaPushSDKInstance.h"
#import "OmniaPushAPNSRegistrationRequestImpl.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define TEST_NOTIFICATION_TYPE UIRemoteNotificationTypeBadge

SPEC_BEGIN(OmniaPushSDKInstanceSpec)

describe(@"OmniaPushSDKInstance", ^{
    
    __block OmniaPushSDKInstance *sdkInstance;
    __block UIApplication *application;
    __block NSObject<OmniaPushAPNSRegistrationRequest> *registrationRequest;
    __block NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy;
    
    beforeEach(^{
        application = [UIApplication sharedApplication];
        registrationRequest = (NSObject<OmniaPushAPNSRegistrationRequest>*) fake_for(@protocol(OmniaPushAPNSRegistrationRequest));
        appDelegateProxy = (NSProxy<OmniaPushAppDelegateProxy>*) fake_for(@protocol(OmniaPushAppDelegateProxy));
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
        
        beforeEach(^{
            sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:application registrationRequest:registrationRequest appDelegateProxy:appDelegateProxy];
        });
        
        it(@"should be constructed successfully", ^{
            sdkInstance should_not be_nil;
        });
        
        it(@"should call register on the registrationRequest successfully", ^{
//            [sdkInstance registerForRemoteNotificationTypes:TEST_NOTIFICATION_TYPE];
//            appDelegateProxy should_have have_received("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE);
//            registrationRequest should_have have_received("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE);
        });
        
    });

});

SPEC_END
