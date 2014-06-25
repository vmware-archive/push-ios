//
//  PMSSPushPersistentStorageSpec.mm
//  PMSSPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "PMSSPersistentStorage+Push.h"
#import "PMSSPushSpecHelper.h"

SPEC_BEGIN(PMSSPushPersistentStorageSpec)

describe(@"PMSSPushPersistentStorage", ^{

    __block PMSSPushSpecHelper *helper;

    beforeEach(^{
        helper = [[PMSSPushSpecHelper alloc] init];
        [PMSSPersistentStorage resetPushPersistedValues];
    });
                   
    it(@"should start empty", ^{
        [[[PMSSPersistentStorage APNSDeviceToken] should] beNil];
        [[[PMSSPersistentStorage serverDeviceID] should] beNil];
        [[[PMSSPersistentStorage variantUUID] should] beNil];
        [[[PMSSPersistentStorage releaseSecret] should] beNil];
        [[[PMSSPersistentStorage deviceAlias] should] beNil];
    });
    
    it(@"should be able to save the APNS device token", ^{
        [PMSSPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [[[PMSSPersistentStorage APNSDeviceToken] should] equal:helper.apnsDeviceToken];
    });
    
    it(@"should be able to save the back-end device ID", ^{
        [PMSSPersistentStorage setServerDeviceID:helper.backEndDeviceId];
        [[[PMSSPersistentStorage serverDeviceID] should] equal:helper.backEndDeviceId];
    });
    
    it(@"should be able to save the release UUID", ^{
        [PMSSPersistentStorage setVariantUUID:TEST_VARIANT_UUID_1];
        [[[PMSSPersistentStorage variantUUID] should] equal:TEST_VARIANT_UUID_1];
    });
    
    it(@"should be able to save the release secret", ^{
        [PMSSPersistentStorage setReleaseSecret:TEST_RELEASE_SECRET_1];
        [[[PMSSPersistentStorage releaseSecret] should] equal:(TEST_RELEASE_SECRET_1)];
    });
    
    it(@"should be able to save the device alias", ^{
        [PMSSPersistentStorage setDeviceAlias:TEST_DEVICE_ALIAS_1];
        [[[PMSSPersistentStorage deviceAlias] should] equal:TEST_DEVICE_ALIAS_1];
    });
    
    it(@"should clear values after being reset", ^{
        [PMSSPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [PMSSPersistentStorage setServerDeviceID:helper.backEndDeviceId];
        [PMSSPersistentStorage resetPushPersistedValues];
        [[[PMSSPersistentStorage APNSDeviceToken] should] beNil];
        [[[PMSSPersistentStorage serverDeviceID] should] beNil];
    });
});

SPEC_END
