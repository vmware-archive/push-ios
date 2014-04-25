//
//  PCFPushPersistentStorageSpec.mm
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPersistentStorage+Push.h"
#import "PCFPushSpecHelper.h"

SPEC_BEGIN(PCFPushPersistentStorageSpec)

describe(@"PCFPushPersistentStorage", ^{

    __block PCFPushSpecHelper *helper;

    beforeEach(^{
        helper = [[PCFPushSpecHelper alloc] init];
        [PCFPersistentStorage resetPushPersistedValues];
    });
                   
    it(@"should start empty", ^{
        [[[PCFPersistentStorage APNSDeviceToken] should] beNil];
        [[[PCFPersistentStorage serverDeviceID] should] beNil];
        [[[PCFPersistentStorage variantUUID] should] beNil];
        [[[PCFPersistentStorage releaseSecret] should] beNil];
        [[[PCFPersistentStorage deviceAlias] should] beNil];
    });
    
    it(@"should be able to save the APNS device token", ^{
        [PCFPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [[[PCFPersistentStorage APNSDeviceToken] should] equal:helper.apnsDeviceToken];
    });
    
    it(@"should be able to save the back-end device ID", ^{
        [PCFPersistentStorage setServerDeviceID:helper.backEndDeviceId];
        [[[PCFPersistentStorage serverDeviceID] should] equal:helper.backEndDeviceId];
    });
    
    it(@"should be able to save the release UUID", ^{
        [PCFPersistentStorage setVariantUUID:TEST_VARIANT_UUID_1];
        [[[PCFPersistentStorage variantUUID] should] equal:TEST_VARIANT_UUID_1];
    });
    
    it(@"should be able to save the release secret", ^{
        [PCFPersistentStorage setReleaseSecret:TEST_RELEASE_SECRET_1];
        [[[PCFPersistentStorage releaseSecret] should] equal:(TEST_RELEASE_SECRET_1)];
    });
    
    it(@"should be able to save the device alias", ^{
        [PCFPersistentStorage setDeviceAlias:TEST_DEVICE_ALIAS_1];
        [[[PCFPersistentStorage deviceAlias] should] equal:TEST_DEVICE_ALIAS_1];
    });
    
    it(@"should clear values after being reset", ^{
        [PCFPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [PCFPersistentStorage setServerDeviceID:helper.backEndDeviceId];
        [PCFPersistentStorage resetPushPersistedValues];
        [[[PCFPersistentStorage APNSDeviceToken] should] beNil];
        [[[PCFPersistentStorage serverDeviceID] should] beNil];
    });
});

SPEC_END
