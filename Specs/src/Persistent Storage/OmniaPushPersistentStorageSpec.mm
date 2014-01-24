#import "OmniaPushPersistentStorage.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushPersistentStorageSpec)

describe(@"OmniaPushPersistentStorage", ^{
    
    __block OmniaPushPersistentStorage *storage;
    __block OmniaSpecHelper *helper;

    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        storage = [[OmniaPushPersistentStorage alloc] init];
        [storage reset];
    });
                   
    it(@"should start empty", ^{
        [storage loadDeviceToken] should be_nil;
    });
    
    it(@"should be able to save the device token", ^{
        [storage saveDeviceToken:helper.deviceToken];
        [storage loadDeviceToken] should equal(helper.deviceToken);
    });
    
    it(@"should clear values after being reset", ^{
        [storage saveDeviceToken:helper.deviceToken];
        [storage reset];
        [storage loadDeviceToken] should be_nil;
    });
});

SPEC_END
