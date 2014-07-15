//
//  MSSPushPersistentStorageSpec.mm
//  MSSPush
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "MSSPersistentStorage+Push.h"
#import "MSSPushSpecHelper.h"

SPEC_BEGIN(MSSPushPersistentStorageSpec)

describe(@"MSSPushPersistentStorage", ^{

    __block MSSPushSpecHelper *helper;

    beforeEach(^{
        helper = [[MSSPushSpecHelper alloc] init];
        [MSSPersistentStorage resetPushPersistedValues];
    });
                   
    it(@"should start empty", ^{
        [[[MSSPersistentStorage APNSDeviceToken] should] beNil];
        [[[MSSPersistentStorage serverDeviceID] should] beNil];
        [[[MSSPersistentStorage variantUUID] should] beNil];
        [[[MSSPersistentStorage releaseSecret] should] beNil];
        [[[MSSPersistentStorage deviceAlias] should] beNil];
    });
    
    it(@"should be able to save the APNS device token", ^{
        [MSSPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [[[MSSPersistentStorage APNSDeviceToken] should] equal:helper.apnsDeviceToken];
    });
    
    it(@"should be able to save the back-end device ID", ^{
        [MSSPersistentStorage setServerDeviceID:helper.backEndDeviceId];
        [[[MSSPersistentStorage serverDeviceID] should] equal:helper.backEndDeviceId];
    });
    
    it(@"should be able to save the release UUID", ^{
        [MSSPersistentStorage setVariantUUID:TEST_VARIANT_UUID_1];
        [[[MSSPersistentStorage variantUUID] should] equal:TEST_VARIANT_UUID_1];
    });
    
    it(@"should be able to save the release secret", ^{
        [MSSPersistentStorage setReleaseSecret:TEST_RELEASE_SECRET_1];
        [[[MSSPersistentStorage releaseSecret] should] equal:(TEST_RELEASE_SECRET_1)];
    });
    
    it(@"should be able to save the device alias", ^{
        [MSSPersistentStorage setDeviceAlias:TEST_DEVICE_ALIAS_1];
        [[[MSSPersistentStorage deviceAlias] should] equal:TEST_DEVICE_ALIAS_1];
    });
    
    it(@"should clear values after being reset", ^{
        [MSSPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [MSSPersistentStorage setServerDeviceID:helper.backEndDeviceId];
        [MSSPersistentStorage resetPushPersistedValues];
        [[[MSSPersistentStorage APNSDeviceToken] should] beNil];
        [[[MSSPersistentStorage serverDeviceID] should] beNil];
    });
});

SPEC_END
