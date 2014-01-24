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
        [storage loadAPNSDeviceToken] should be_nil;
    });
    
    it(@"should be able to save the APNS device token", ^{
        [storage saveAPNSDeviceToken:helper.apnsDeviceToken];
        [storage loadAPNSDeviceToken] should equal(helper.apnsDeviceToken);
    });
    
    it(@"should clear values after being reset", ^{
        [storage saveAPNSDeviceToken:helper.apnsDeviceToken];
        [storage reset];
        [storage loadAPNSDeviceToken] should be_nil;
    });
});

SPEC_END
