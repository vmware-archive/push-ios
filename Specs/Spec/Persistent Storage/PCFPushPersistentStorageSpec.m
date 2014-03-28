//
//  PCFPushPersistentStorageSpec.mm
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPushPersistentStorage.h"
#import "PCFPushSpecHelper.h"

SPEC_BEGIN(PCFPushPersistentStorageSpec)

describe(@"PCFPushPersistentStorage", ^{

    __block PCFPushSpecHelper *helper;

    beforeEach(^{
        helper = [[PCFPushSpecHelper alloc] init];
        [PCFPushPersistentStorage reset];
    });
                   
    it(@"should start empty", ^{
        [[[PCFPushPersistentStorage APNSDeviceToken] should] beNil];
        [[[PCFPushPersistentStorage backEndDeviceID] should] beNil];
        [[[PCFPushPersistentStorage releaseUUID] should] beNil];
        [[[PCFPushPersistentStorage releaseSecret] should] beNil];
        [[[PCFPushPersistentStorage deviceAlias] should] beNil];
    });
    
    it(@"should be able to save the APNS device token", ^{
        [PCFPushPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [[[PCFPushPersistentStorage APNSDeviceToken] should] equal:helper.apnsDeviceToken];
    });
    
    it(@"should be able to save the back-end device ID", ^{
        [PCFPushPersistentStorage setBackEndDeviceID:helper.backEndDeviceId];
        [[[PCFPushPersistentStorage backEndDeviceID] should] equal:helper.backEndDeviceId];
    });
    
    it(@"should be able to save the release UUID", ^{
        [PCFPushPersistentStorage setReleaseUUID:TEST_RELEASE_UUID_1];
        [[[PCFPushPersistentStorage releaseUUID] should] equal:TEST_RELEASE_UUID_1];
    });
    
    it(@"should be able to save the release secret", ^{
        [PCFPushPersistentStorage setReleaseSecret:TEST_RELEASE_SECRET_1];
        [[[PCFPushPersistentStorage releaseSecret] should] equal:(TEST_RELEASE_SECRET_1)];
    });
    
    it(@"should be able to save the device alias", ^{
        [PCFPushPersistentStorage setDeviceAlias:TEST_DEVICE_ALIAS_1];
        [[[PCFPushPersistentStorage deviceAlias] should] equal:TEST_DEVICE_ALIAS_1];
    });
    
    it(@"should clear values after being reset", ^{
        [PCFPushPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [PCFPushPersistentStorage setBackEndDeviceID:helper.backEndDeviceId];
        [PCFPushPersistentStorage reset];
        [[[PCFPushPersistentStorage APNSDeviceToken] should] beNil];
        [[[PCFPushPersistentStorage backEndDeviceID] should] beNil];
    });
});

SPEC_END
