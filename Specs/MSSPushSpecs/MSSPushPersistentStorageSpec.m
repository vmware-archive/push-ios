//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"

#import "MSSPersistentStorage+Push.h"
#import "MSSPushSpecsHelper.h"

SPEC_BEGIN(MSSPushPersistentStorageSpec)

describe(@"MSSPushPersistentStorage", ^{

    __block MSSPushSpecsHelper *helper;

    beforeEach(^{
        helper = [[MSSPushSpecsHelper alloc] init];
        [MSSPersistentStorage resetPushPersistedValues];
    });
                   
    it(@"should start empty", ^{
        [[[MSSPersistentStorage APNSDeviceToken] should] beNil];
        [[[MSSPersistentStorage serverDeviceID] should] beNil];
        [[[MSSPersistentStorage variantUUID] should] beNil];
        [[[MSSPersistentStorage variantSecret] should] beNil];
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
    
    it(@"should be able to save the variant UUID", ^{
        [MSSPersistentStorage setVariantUUID:TEST_VARIANT_UUID_1];
        [[[MSSPersistentStorage variantUUID] should] equal:TEST_VARIANT_UUID_1];
    });
    
    it(@"should be able to save the variant secret", ^{
        [MSSPersistentStorage setVariantSecret:TEST_VARIANT_SECRET_1];
        [[[MSSPersistentStorage variantSecret] should] equal:(TEST_VARIANT_SECRET_1)];
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
