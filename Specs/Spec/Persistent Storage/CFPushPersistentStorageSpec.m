//
//  CFPushPersistentStorageSpec.mm
//  CFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "CFPushPersistentStorage.h"
#import "CFSpecHelper.h"

SPEC_BEGIN(CFPushPersistentStorageSpec)

describe(@"CFPushPersistentStorage", ^{

    __block CFSpecHelper *helper;

    beforeEach(^{
        helper = [[CFSpecHelper alloc] init];
        [CFPushPersistentStorage reset];
    });
                   
    it(@"should start empty", ^{
        [[[CFPushPersistentStorage APNSDeviceToken] should] beNil];
        [[[CFPushPersistentStorage backEndDeviceID] should] beNil];
        [[[CFPushPersistentStorage releaseUUID] should] beNil];
        [[[CFPushPersistentStorage releaseSecret] should] beNil];
        [[[CFPushPersistentStorage deviceAlias] should] beNil];
    });
    
    it(@"should be able to save the APNS device token", ^{
        [CFPushPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [[[CFPushPersistentStorage APNSDeviceToken] should] equal:helper.apnsDeviceToken];
    });
    
    it(@"should be able to save the back-end device ID", ^{
        [CFPushPersistentStorage setBackEndDeviceID:helper.backEndDeviceId];
        [[[CFPushPersistentStorage backEndDeviceID] should] equal:helper.backEndDeviceId];
    });
    
    it(@"should be able to save the release UUID", ^{
        [CFPushPersistentStorage setReleaseUUID:TEST_RELEASE_UUID_1];
        [[[CFPushPersistentStorage releaseUUID] should] equal:TEST_RELEASE_UUID_1];
    });
    
    it(@"should be able to save the release secret", ^{
        [CFPushPersistentStorage setReleaseSecret:TEST_RELEASE_SECRET_1];
        [[[CFPushPersistentStorage releaseSecret] should] equal:(TEST_RELEASE_SECRET_1)];
    });
    
    it(@"should be able to save the device alias", ^{
        [CFPushPersistentStorage setDeviceAlias:TEST_DEVICE_ALIAS_1];
        [[[CFPushPersistentStorage deviceAlias] should] equal:TEST_DEVICE_ALIAS_1];
    });
    
    it(@"should clear values after being reset", ^{
        [CFPushPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [CFPushPersistentStorage setBackEndDeviceID:helper.backEndDeviceId];
        [CFPushPersistentStorage reset];
        [[[CFPushPersistentStorage APNSDeviceToken] should] beNil];
        [[[CFPushPersistentStorage backEndDeviceID] should] beNil];
    });
});

SPEC_END
