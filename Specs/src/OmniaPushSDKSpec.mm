#import "OmniaPushSDKInstance.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushSDKSpec)

describe(@"OmniaPushSDK", ^{
    
    __block OmniaPushSDKInstance *model;

    it(@"should be able to initialize the SDK", ^{
        [[OmniaPushSDKInstance alloc] init] should_not be_nil;
    });
});

SPEC_END
