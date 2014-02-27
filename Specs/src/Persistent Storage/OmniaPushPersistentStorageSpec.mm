//
//  OmniaPushPersistentStorageSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

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
        [storage loadBackEndDeviceID] should be_nil;
        [storage loadReleaseUuid] should be_nil;
        [storage loadReleaseSecret] should be_nil;
        [storage loadDeviceAlias] should be_nil;
    });
    
    it(@"should be able to save the APNS device token", ^{
        [storage saveAPNSDeviceToken:helper.apnsDeviceToken];
        [storage loadAPNSDeviceToken] should equal(helper.apnsDeviceToken);
    });
    
    it(@"should be able to save the back-end device ID", ^{
        [storage saveBackEndDeviceID:helper.backEndDeviceId];
        [storage loadBackEndDeviceID] should equal(helper.backEndDeviceId);
    });
    
    it(@"should be able to save the release UUID", ^{
        [storage saveReleaseUuid:TEST_RELEASE_UUID];
        [storage loadReleaseUuid] should equal(TEST_RELEASE_UUID);
    });
    
    it(@"should be able to save the release secret", ^{
        [storage saveReleaseSecret:TEST_RELEASE_SECRET];
        [storage loadReleaseSecret] should equal(TEST_RELEASE_SECRET);
    });
    
    it(@"should be able to save the device alias", ^{
        [storage saveDeviceAlias:TEST_DEVICE_ALIAS];
        [storage loadDeviceAlias] should equal(TEST_DEVICE_ALIAS);
    });
    
    it(@"should clear values after being reset", ^{
        [storage saveAPNSDeviceToken:helper.apnsDeviceToken];
        [storage saveBackEndDeviceID:helper.backEndDeviceId];
        [storage reset];
        [storage loadAPNSDeviceToken] should be_nil;
        [storage loadBackEndDeviceID] should be_nil;
    });
});

SPEC_END
