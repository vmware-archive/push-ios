#import "OmniaPushSDK.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushSDKSpec)

describe(@"OmniaPushSDK", ^{
    __block OmniaPushSDK *model;

    it(@"should be able to initialize the SDK", ^{
        [[OmniaPushSDK alloc] init] should_not be_nil;
    });
});

SPEC_END
