//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"

#import "MSSPushRegistrationResponseData.h"
#import "MSSPushRegistrationRequestData.h"
#import "MSSPushBackEndRegistrationDataTest.h"
#import "MSSPushBackEndRegistrationResponseDataTest.h"
#import "NSObject+MSSJsonizable.h"
#import "MSSPushErrors.h"


SPEC_BEGIN(MSSPushBackEndRegistrationResponseDataSpec)

describe(@"MSSPushBackEndRegistrationResponseData", ^{
    
    __block MSSPushRegistrationResponseData *model;
    
    afterEach(^{
        model = nil;
    });
    
    it(@"should be initializable", ^{
        model = [[MSSPushRegistrationResponseData alloc] init];
        [[model shouldNot] beNil];
    });
    
    context(@"fields", ^{
        
        beforeEach(^{
            model = [[MSSPushRegistrationResponseData alloc] init];
        });
        
        it(@"should start as nil", ^{
            [[model.variantUUID should] beNil];
            [[model.deviceUUID should] beNil];
            [[model.deviceAlias should] beNil];
            [[model.deviceManufacturer should] beNil];
            [[model.deviceModel should] beNil];
            [[model.os should] beNil];
            [[model.osVersion should] beNil];
            [[model.registrationToken should] beNil];
        });
        
        it(@"should have a variant_uuid", ^{
            model.variantUUID = TEST_VARIANT_UUID;
            [[model.variantUUID should] equal:TEST_VARIANT_UUID];
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
            model = [MSSPushRegistrationResponseData mss_fromJSONData:nil error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
            [[error.domain should] equal:MSSPushErrorDomain];
            [[theValue(error.code) should] equal:theValue(MSSPushBackEndRegistrationDataUnparseable)];
        });
        
        it(@"should handle empty input", ^{
            NSError *error;
            model = [MSSPushRegistrationResponseData mss_fromJSONData:[NSData data] error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
            [[error.domain should] equal:MSSPushErrorDomain];
            [[theValue(error.code) should] equal:theValue(MSSPushBackEndRegistrationDataUnparseable)];
        });
        
        it(@"should handle bad JSON", ^{
            NSError *error;
            NSData *JSONData = [@"I AM NOT JSON" dataUsingEncoding:NSUTF8StringEncoding];
            model = [MSSPushRegistrationResponseData mss_fromJSONData:JSONData error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
        });
        
        it(@"should construct a complete response object", ^{
            NSError *error;
            NSDictionary *dict = @{
                                   RegistrationAttributes.deviceOS           : TEST_OS,
                                   RegistrationAttributes.deviceOSVersion    : TEST_OS_VERSION,
                                   RegistrationAttributes.deviceAlias        : TEST_DEVICE_ALIAS,
                                   RegistrationAttributes.deviceManufacturer : TEST_DEVICE_MANUFACTURER,
                                   RegistrationAttributes.deviceModel        : TEST_DEVICE_MODEL,
                                   RegistrationAttributes.variantUUID        : TEST_VARIANT_UUID,
                                   RegistrationAttributes.registrationToken  : TEST_REGISTRATION_TOKEN,
                                   kDeviceUUID                               : TEST_DEVICE_UUID,
                                   };

            NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
            [[error should] beNil];
            [[data shouldNot] beNil];
            
            model = [MSSPushRegistrationResponseData mss_fromJSONData:data error:&error];
            [[error should] beNil];
            [[model.os should] equal:TEST_OS];
            [[model.osVersion should] equal:TEST_OS_VERSION];
            [[model.deviceUUID should] equal:TEST_DEVICE_UUID];
            [[model.deviceAlias should] equal:TEST_DEVICE_ALIAS];
            [[model.deviceManufacturer should] equal:TEST_DEVICE_MANUFACTURER];
            [[model.deviceModel should] equal:TEST_DEVICE_MODEL];
            [[model.variantUUID should] equal:TEST_VARIANT_UUID];
            [[model.registrationToken should] equal:TEST_REGISTRATION_TOKEN];
        });
    });
    
    context(@"serialization", ^{
        
        __block NSDictionary *dict = nil;
        
        beforeEach(^{
            model = [[MSSPushRegistrationResponseData alloc] init];
        });
        
        afterEach(^{
            dict = nil;
        });
        
        context(@"populated object", ^{
            
            beforeEach(^{
                model.variantUUID = TEST_VARIANT_UUID;
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
                [[dict[RegistrationAttributes.variantUUID] should] equal:TEST_VARIANT_UUID];
                [[dict[kDeviceUUID] should] equal:TEST_DEVICE_UUID];
                [[dict[RegistrationAttributes.deviceAlias] should] equal:TEST_DEVICE_ALIAS];
                [[dict[RegistrationAttributes.deviceManufacturer] should] equal:TEST_DEVICE_MANUFACTURER];
                [[dict[RegistrationAttributes.deviceModel] should] equal:TEST_DEVICE_MODEL];
                [[dict[RegistrationAttributes.deviceOS] should] equal:TEST_OS];
                [[dict[RegistrationAttributes.deviceOSVersion] should] equal:TEST_OS_VERSION];
                [[dict[RegistrationAttributes.registrationToken] should] equal:TEST_REGISTRATION_TOKEN];
            });
            
            it(@"should be dictionaryizable", ^{
                dict = [model mss_toFoundationType];
            });
            
            it(@"should be JSONizable", ^{
                NSData *JSONData = [model mss_toJSONData:nil];
                [[JSONData shouldNot] beNil];
                NSError *error = nil;
                dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
                [[error should] beNil];
            });
        });
        
        context(@"unpopulated object", ^{
            
            afterEach(^{
                [[dict shouldNot] beNil];
                [[dict[RegistrationAttributes.variantUUID] should] beNil];
                [[dict[kDeviceUUID] should] beNil];
                [[dict[RegistrationAttributes.deviceAlias] should] beNil];
                [[dict[RegistrationAttributes.deviceManufacturer] should] beNil];
                [[dict[RegistrationAttributes.deviceModel] should] beNil];
                [[dict[RegistrationAttributes.deviceOS] should] beNil];
                [[dict[RegistrationAttributes.deviceOSVersion] should] beNil];
                [[dict[RegistrationAttributes.registrationToken] should] beNil];
            });
            
            it(@"should be dictionaryizable", ^{
                dict = [model mss_toFoundationType];
            });
            
            it(@"should be JSONizable", ^{
                NSData *JSONData = [model mss_toJSONData:nil];
                [[JSONData shouldNot] beNil];
                NSError *error = nil;
                dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
                [[error should] beNil];
            });
        });
    });
});

SPEC_END
