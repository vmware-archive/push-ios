//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"

#import "MSSPushPersistentStorage.h"
#import "MSSPushSpecsHelper.h"

SPEC_BEGIN(MSSPushPersistentStorageSpec)

describe(@"MSSPushPersistentStorage", ^{

    __block MSSPushSpecsHelper *helper;

    beforeEach(^{
        helper = [[MSSPushSpecsHelper alloc] init];
        [MSSPushPersistentStorage reset];
    });
                   
    it(@"should start empty", ^{
        [[[MSSPushPersistentStorage APNSDeviceToken] should] beNil];
        [[[MSSPushPersistentStorage serverDeviceID] should] beNil];
        [[[MSSPushPersistentStorage variantUUID] should] beNil];
        [[[MSSPushPersistentStorage variantSecret] should] beNil];
        [[[MSSPushPersistentStorage deviceAlias] should] beNil];
    });
    
    it(@"should be able to save the APNS device token", ^{
        [MSSPushPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [[[MSSPushPersistentStorage APNSDeviceToken] should] equal:helper.apnsDeviceToken];
    });
    
    it(@"should be able to save the back-end device ID", ^{
        [MSSPushPersistentStorage setServerDeviceID:helper.backEndDeviceId];
        [[[MSSPushPersistentStorage serverDeviceID] should] equal:helper.backEndDeviceId];
    });
    
    it(@"should be able to save the variant UUID", ^{
        [MSSPushPersistentStorage setVariantUUID:TEST_VARIANT_UUID_1];
        [[[MSSPushPersistentStorage variantUUID] should] equal:TEST_VARIANT_UUID_1];
    });
    
    it(@"should be able to save the variant secret", ^{
        [MSSPushPersistentStorage setVariantSecret:TEST_VARIANT_SECRET_1];
        [[[MSSPushPersistentStorage variantSecret] should] equal:(TEST_VARIANT_SECRET_1)];
    });
    
    it(@"should be able to save the device alias", ^{
        [MSSPushPersistentStorage setDeviceAlias:TEST_DEVICE_ALIAS_1];
        [[[MSSPushPersistentStorage deviceAlias] should] equal:TEST_DEVICE_ALIAS_1];
    });
    
    it(@"should clear values after being reset", ^{
        [MSSPushPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [MSSPushPersistentStorage setServerDeviceID:helper.backEndDeviceId];
        [MSSPushPersistentStorage reset];
        [[[MSSPushPersistentStorage APNSDeviceToken] should] beNil];
        [[[MSSPushPersistentStorage serverDeviceID] should] beNil];
    });
});

SPEC_END
