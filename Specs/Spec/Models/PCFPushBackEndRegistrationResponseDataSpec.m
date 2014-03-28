//
//  PCFPushBackEndRegistrationResponseDataSpec.mm
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPushRegistrationResponseData.h"
#import "PCFPushRegistrationRequestData.h"
#import "PCFPushBackEndRegistrationDataTest.h"
#import "PCFPushBackEndRegistrationResponseDataTest.h"
#import "PCFPushErrors.h"


SPEC_BEGIN(PCFPushBackEndRegistrationResponseDataSpec)

describe(@"PCFPushBackEndRegistrationResponseData", ^{
    
    __block PCFPushRegistrationResponseData *model;
    
    afterEach(^{
        model = nil;
    });
    
    it(@"should be initializable", ^{
        model = [[PCFPushRegistrationResponseData alloc] init];
        [[model shouldNot] beNil];
    });
    
    context(@"fields", ^{
        
        beforeEach(^{
            model = [[PCFPushRegistrationResponseData alloc] init];
        });
        
        it(@"should start as nil", ^{
            [[model.releaseUUID should] beNil];
            [[model.deviceUUID should] beNil];
            [[model.deviceAlias should] beNil];
            [[model.deviceManufacturer should] beNil];
            [[model.deviceModel should] beNil];
            [[model.os should] beNil];
            [[model.osVersion should] beNil];
            [[model.registrationToken should] beNil];
        });
        
        it(@"should have a release_UUID", ^{
            model.releaseUUID = TEST_RELEASE_UUID;
            [[model.releaseUUID should] equal:TEST_RELEASE_UUID];
        });
        
        it(@"should have a deviceUUID", ^{
            model.deviceUUID = TEST_DEVICE_UUID;
            [[model.deviceUUID should] equal:TEST_DEVICE_UUID];
        });
        
        it(@"should have a device_alias", ^{
            model.deviceAlias = TEST_DEVICE_ALIAS;
            [[model.deviceAlias should] equal:TEST_DEVICE_ALIAS];
        });
        
        it(@"should have a device_manufacturer", ^{
            model.deviceManufacturer = TEST_DEVICE_MANUFACTURER;
            [[model.deviceManufacturer should] equal:TEST_DEVICE_MANUFACTURER];
        });
        
        it(@"should have a device_model", ^{
            model.deviceModel = TEST_DEVICE_MODEL;
            [[model.deviceModel should] equal:TEST_DEVICE_MODEL];
        });
        
        it(@"should have an os", ^{
            model.os = TEST_OS;
            [[model.os should] equal:TEST_OS];
        });
        
        it(@"should have an os_version", ^{
            model.os = TEST_OS_VERSION;
            [[model.os should] equal:TEST_OS_VERSION];
        });
        
        it(@"should have an registration_token", ^{
            model.registrationToken = TEST_REGISTRATION_TOKEN;
            [[model.registrationToken should] equal:TEST_REGISTRATION_TOKEN];
        });
    });
    
    context(@"deserialization", ^{
        
        it(@"should handle a nil input", ^{
            NSError *error;
            model = [PCFPushRegistrationResponseData fromJSONData:nil error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
            [[error.domain should] equal:PCFPushErrorDomain];
            [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationDataUnparseable)];
        });
        
        it(@"should handle empty input", ^{
            NSError *error;
            model = [PCFPushRegistrationResponseData fromJSONData:[NSData data] error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
            [[error.domain should] equal:PCFPushErrorDomain];
            [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationDataUnparseable)];
        });
        
        it(@"should handle bad JSON", ^{
            NSError *error;
            NSData *JSONData = [@"I AM NOT JSON" dataUsingEncoding:NSUTF8StringEncoding];
            model = [PCFPushRegistrationResponseData fromJSONData:JSONData error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
        });
        
        it(@"should construct a complete response object", ^{
            NSError *error;
            id dict = @{
                        kDeviceOS : TEST_OS,
                        kDeviceOSVersion : TEST_OS_VERSION,
                        kDeviceUUID : TEST_DEVICE_UUID,
                        kDeviceAlias : TEST_DEVICE_ALIAS,
                        kDeviceManufacturer : TEST_DEVICE_MANUFACTURER,
                        kDeviceModel : TEST_DEVICE_MODEL,
                        kReleaseUUID : TEST_RELEASE_UUID,
                        kRegistrationToken : TEST_REGISTRATION_TOKEN,
                        };
            NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
            [[error should] beNil];
            [[data shouldNot] beNil];
            
            model = [PCFPushRegistrationResponseData fromJSONData:data error:&error];
            [[error should] beNil];
            [[model.os should] equal:TEST_OS];
            [[model.osVersion should] equal:TEST_OS_VERSION];
            [[model.deviceUUID should] equal:TEST_DEVICE_UUID];
            [[model.deviceAlias should] equal:TEST_DEVICE_ALIAS];
            [[model.deviceManufacturer should] equal:TEST_DEVICE_MANUFACTURER];
            [[model.deviceModel should] equal:TEST_DEVICE_MODEL];
            [[model.releaseUUID should] equal:TEST_RELEASE_UUID];
            [[model.registrationToken should] equal:TEST_REGISTRATION_TOKEN];
        });
    });
    
    context(@"serialization", ^{
        
        __block NSDictionary *dict = nil;
        
        beforeEach(^{
            model = [[PCFPushRegistrationResponseData alloc] init];
        });
        
        afterEach(^{
            dict = nil;
        });
        
        context(@"populated object", ^{
            
            beforeEach(^{
                model.releaseUUID = TEST_RELEASE_UUID;
                model.deviceUUID = TEST_DEVICE_UUID;
                model.deviceAlias = TEST_DEVICE_ALIAS;
                model.deviceManufacturer = TEST_DEVICE_MANUFACTURER;
                model.deviceModel = TEST_DEVICE_MODEL;
                model.os = TEST_OS;
                model.osVersion = TEST_OS_VERSION;
                model.registrationToken = TEST_REGISTRATION_TOKEN;
            });
            
            afterEach(^{
                [[dict shouldNot] beNil];
                [[dict[kReleaseUUID] should] equal:TEST_RELEASE_UUID];
                [[dict[kDeviceUUID] should] equal:TEST_DEVICE_UUID];
                [[dict[kDeviceAlias] should] equal:TEST_DEVICE_ALIAS];
                [[dict[kDeviceManufacturer] should] equal:TEST_DEVICE_MANUFACTURER];
                [[dict[kDeviceModel] should] equal:TEST_DEVICE_MODEL];
                [[dict[kDeviceOS] should] equal:TEST_OS];
                [[dict[kDeviceOSVersion] should] equal:TEST_OS_VERSION];
                [[dict[kRegistrationToken] should] equal:TEST_REGISTRATION_TOKEN];
            });
            
            it(@"should be dictionaryizable", ^{
                dict = [model toDictionary];
            });
            
            it(@"should be JSONizable", ^{
                NSData *JSONData = [model toJSONData:nil];
                [[JSONData shouldNot] beNil];
                NSError *error = nil;
                dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
                [[error should] beNil];
            });
        });
        
        context(@"unpopulated object", ^{
            
            afterEach(^{
                [[dict shouldNot] beNil];
                [[dict[kReleaseUUID] should] beNil];
                [[dict[kDeviceUUID] should] beNil];
                [[dict[kDeviceAlias] should] beNil];
                [[dict[kDeviceManufacturer] should] beNil];
                [[dict[kDeviceModel] should] beNil];
                [[dict[kDeviceOS] should] beNil];
                [[dict[kDeviceOSVersion] should] beNil];
                [[dict[kRegistrationToken] should] beNil];
            });
            
            it(@"should be dictionaryizable", ^{
                dict = [model toDictionary];
            });
            
            it(@"should be JSONizable", ^{
                NSData *JSONData = [model toJSONData:nil];
                [[JSONData shouldNot] beNil];
                NSError *error = nil;
                dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
                [[error should] beNil];
            });
        });
    });
});

SPEC_END
