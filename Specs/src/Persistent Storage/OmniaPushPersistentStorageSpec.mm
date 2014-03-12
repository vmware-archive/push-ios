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

    __block OmniaSpecHelper *helper;

    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [OmniaPushPersistentStorage reset];
    });
                   
    it(@"should start empty", ^{
        [OmniaPushPersistentStorage APNSDeviceToken] should be_nil;
        [OmniaPushPersistentStorage backEndDeviceID] should be_nil;
        [OmniaPushPersistentStorage releaseUUID] should be_nil;
        [OmniaPushPersistentStorage releaseSecret] should be_nil;
        [OmniaPushPersistentStorage deviceAlias] should be_nil;
    });
    
    it(@"should be able to save the APNS device token", ^{
        [OmniaPushPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [OmniaPushPersistentStorage APNSDeviceToken] should equal(helper.apnsDeviceToken);
    });
    
    it(@"should be able to save the back-end device ID", ^{
        [OmniaPushPersistentStorage setBackEndDeviceID:helper.backEndDeviceId];
        [OmniaPushPersistentStorage backEndDeviceID] should equal(helper.backEndDeviceId);
    });
    
    it(@"should be able to save the release UUID", ^{
        [OmniaPushPersistentStorage setReleaseUUID:TEST_RELEASE_UUID];
        [OmniaPushPersistentStorage releaseUUID] should equal(TEST_RELEASE_UUID);
    });
    
    it(@"should be able to save the release secret", ^{
        [OmniaPushPersistentStorage setReleaseSecret:TEST_RELEASE_SECRET];
        [OmniaPushPersistentStorage releaseSecret] should equal(TEST_RELEASE_SECRET);
    });
    
    it(@"should be able to save the device alias", ^{
        [OmniaPushPersistentStorage setDeviceAlias:TEST_DEVICE_ALIAS];
        [OmniaPushPersistentStorage deviceAlias] should equal(TEST_DEVICE_ALIAS);
    });
    
    it(@"should clear values after being reset", ^{
        [OmniaPushPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [OmniaPushPersistentStorage setBackEndDeviceID:helper.backEndDeviceId];
        [OmniaPushPersistentStorage reset];
        [OmniaPushPersistentStorage APNSDeviceToken] should be_nil;
        [OmniaPushPersistentStorage backEndDeviceID] should be_nil;
    });
});

SPEC_END
