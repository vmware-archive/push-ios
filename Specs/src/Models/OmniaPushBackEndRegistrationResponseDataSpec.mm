//
//  OmniaPushBackEndRegistrationResponseDataSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndRegistrationResponseData.h"
#import "OmniaPushBackEndRegistrationRequestData.h"
#import "OmniaPushBackEndRegistrationDataTest.h"
#import "OmniaPushBackEndRegistrationResponseDataTest.h"
#import "OmniaPushErrors.h"

static NSString *const TEST_RELEASE_UUID         = @"123-456-789";
static NSString *const TEST_DEVICE_UUID          = @"L337-L337-OH-YEAH";
static NSString *const TEST_DEVICE_ALIAS         = @"l33t devices of badness";
static NSString *const TEST_DEVICE_MANUFACTURER  = @"Amiga";
static NSString *const TEST_DEVICE_MODEL         = @"500";
static NSString *const TEST_OS                   = @"AmigaOS";
static NSString *const TEST_OS_VERSION           = @"5.0";
static NSString *const TEST_REGISTRATION_TOKEN   = @"ABC-DEF-GHI";

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushBackEndRegistrationResponseDataSpec)

describe(@"OmniaPushBackEndRegistrationResponseData", ^{
    
    __block OmniaPushBackEndRegistrationResponseData *model;
    
    afterEach(^{
        model = nil;
    });
    
    it(@"should be initializable", ^{
        model = [[OmniaPushBackEndRegistrationResponseData alloc] init];
        model should_not be_nil;
    });
    
    context(@"fields", ^{
        
        beforeEach(^{
            model = [[OmniaPushBackEndRegistrationResponseData alloc] init];
        });
        
        it(@"should start as nil", ^{
            model.releaseUUID should be_nil;
            model.deviceUUID should be_nil;
            model.deviceAlias should be_nil;
            model.deviceManufacturer should be_nil;
            model.deviceModel should be_nil;
            model.os should be_nil;
            model.osVersion should be_nil;
            model.registrationToken should be_nil;
        });
        
        it(@"should have a release_UUID", ^{
            model.releaseUUID = TEST_RELEASE_UUID;
            model.releaseUUID should equal(TEST_RELEASE_UUID);
        });
        
        it(@"should have a deviceUUID", ^{
            model.deviceUUID = TEST_DEVICE_UUID;
            model.deviceUUID should equal(TEST_DEVICE_UUID);
        });
        
        it(@"should have a device_alias", ^{
            model.deviceAlias = TEST_DEVICE_ALIAS;
            model.deviceAlias should equal(TEST_DEVICE_ALIAS);
        });
        
        it(@"should have a device_manufacturer", ^{
            model.deviceManufacturer = TEST_DEVICE_MANUFACTURER;
            model.deviceManufacturer should equal(TEST_DEVICE_MANUFACTURER);
        });
        
        it(@"should have a device_model", ^{
            model.deviceModel = TEST_DEVICE_MODEL;
            model.deviceModel should equal(TEST_DEVICE_MODEL);
        });
        
        it(@"should have an os", ^{
            model.os = TEST_OS;
            model.os should equal(TEST_OS);
        });
        
        it(@"should have an os_version", ^{
            model.os = TEST_OS_VERSION;
            model.os should equal(TEST_OS_VERSION);
        });
        
        it(@"should have an registration_token", ^{
            model.registrationToken = TEST_REGISTRATION_TOKEN;
            model.registrationToken should equal(TEST_REGISTRATION_TOKEN);
        });
    });
    
    context(@"deserialization", ^{
        
        __block NSError *error = nil;
        
        afterEach(^{
            error = nil;
        });
        
        it(@"should handle a nil input", ^{
            model = [OmniaPushBackEndRegistrationResponseData fromJSONData:nil error:&error];
            model should be_nil;
            error should_not be_nil;
            error.domain should equal(OmniaPushErrorDomain);
            error.code should equal(OmniaPushBackEndRegistrationResponseDataUnparseable);
        });
        
        it(@"should handle empty input", ^{
            model = [OmniaPushBackEndRegistrationResponseData fromJSONData:[NSData data] error:&error];
            model should be_nil;
            error should_not be_nil;
            error.domain should equal(OmniaPushErrorDomain);
            error.code should equal(OmniaPushBackEndRegistrationResponseDataUnparseable);
        });
        
        it(@"should handle bad JSON", ^{
            NSData *JSONData = [@"I AM NOT JSON" dataUsingEncoding:NSUTF8StringEncoding];
            model = [OmniaPushBackEndRegistrationResponseData fromJSONData:JSONData error:&error];
            model should be_nil;
            error should_not be_nil;
        });
        
        it(@"should construct a complete response object", ^{
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
            error should be_nil;
            data should_not be_nil;
            model = [OmniaPushBackEndRegistrationResponseData fromJSONData:data error:&error];
            model.os should equal(TEST_OS);
            model.osVersion should equal(TEST_OS_VERSION);
            model.deviceUUID should equal(TEST_DEVICE_UUID);
            model.deviceAlias should equal(TEST_DEVICE_ALIAS);
            model.deviceManufacturer should equal(TEST_DEVICE_MANUFACTURER);
            model.deviceModel should equal(TEST_DEVICE_MODEL);
            model.releaseUUID should equal(TEST_RELEASE_UUID);
            model.registrationToken should equal(TEST_REGISTRATION_TOKEN);
        });
    });
    
    context(@"serialization", ^{
        
        __block NSDictionary *dict = nil;
        
        beforeEach(^{
            model = [[OmniaPushBackEndRegistrationResponseData alloc] init];
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
                dict should_not be_nil;
                dict[kReleaseUUID] should equal(TEST_RELEASE_UUID);
                dict[kDeviceUUID] should equal(TEST_DEVICE_UUID);
                dict[kDeviceAlias] should equal(TEST_DEVICE_ALIAS);
                dict[kDeviceManufacturer] should equal(TEST_DEVICE_MANUFACTURER);
                dict[kDeviceModel] should equal(TEST_DEVICE_MODEL);
                dict[kDeviceOS] should equal(TEST_OS);
                dict[kDeviceOSVersion] should equal(TEST_OS_VERSION);
                dict[kRegistrationToken] should equal(TEST_REGISTRATION_TOKEN);
            });
            
            it(@"should be dictionaryizable", ^{
                dict = [model toDictionary];
            });
            
            it(@"should be JSONizable", ^{
                NSData *JSONData = [model toJSONData];
                JSONData should_not be_nil;
                NSError *error = nil;
                dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
                error should be_nil;
            });
        });
        
        context(@"unpopulated object", ^{
            
            afterEach(^{
                dict should_not be_nil;
                dict[kReleaseUUID] should be_nil;
                dict[kDeviceUUID] should be_nil;
                dict[kDeviceAlias] should be_nil;
                dict[kDeviceManufacturer] should be_nil;
                dict[kDeviceModel] should be_nil;
                dict[kDeviceOS] should be_nil;
                dict[kDeviceOSVersion] should be_nil;
                dict[kRegistrationToken] should be_nil;
            });
            
            it(@"should be dictionaryizable", ^{
                dict = [model toDictionary];
            });
            
            it(@"should be JSONizable", ^{
                NSData *JSONData = [model toJSONData];
                JSONData should_not be_nil;
                NSError *error = nil;
                dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
                error should be_nil;
            });
        });
    });
});

SPEC_END
