#import "OmniaPushSDK.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushSDKSpec)

describe(@"OmniaPushSDK", ^{

    __block OmniaPushSDK *sdk;
 
    beforeEach(^{

    });
    
    describe(@"if you try to register", ^{

        it(@"it should succeed", ^{
            sdk = [OmniaPushSDK registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge];
            sdk should_not be_nil;
        });
        
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
