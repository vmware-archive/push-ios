//
//  OmniaPushBackEndRegistrationRequestDataSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushBackEndRegistrationRequestData.h"
#import "OmniaPushErrors.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

static NSString *const TEST_RELEASE_UUID        = @"123-456-789";
static NSString *const TEST_SECRET              =  @"My cat's breath smells like cat food";
static NSString *const TEST_DEVICE_ALIAS        =  @"l33t devices of badness";
static NSString *const TEST_DEVICE_MANUFACTURER = @"Commodore";
static NSString *const TEST_DEVICE_MODEL        = @"64C";
static NSString *const TEST_OS                  = @"BASIC";
static NSString *const TEST_OS_VERSION          = @"2.0";
static NSString *const TEST_REGISTRATION_TOKEN  = @"ABC-DEF-GHI";

SPEC_BEGIN(OmniaPushBackEndRegistrationRequestDataSpec)

describe(@"OmniaPushBackEndRegistrationRequestData", ^{
    
    __block OmniaPushBackEndRegistrationRequestData *model;
    
    afterEach(^{
        model = nil;
    });
    
    it(@"should be initializable", ^{
        model = [[OmniaPushBackEndRegistrationRequestData alloc] init];
        model should_not be_nil;
    });
    
    context(@"fields", ^{
        
        beforeEach(^{
            model = [[OmniaPushBackEndRegistrationRequestData alloc] init];
        });
        
        it(@"should start as nil", ^{
            model.releaseUuid should be_nil;
            model.secret should be_nil;
            model.deviceAlias should be_nil;
            model.deviceManufacturer should be_nil;
            model.deviceModel should be_nil;
            model.os should be_nil;
            model.osVersion should be_nil;
            model.registrationToken should be_nil;
        });
        
        it(@"should have a release_uuid", ^{
            model.releaseUuid = TEST_RELEASE_UUID;
            model.releaseUuid should equal(TEST_RELEASE_UUID);
        });
        
        it(@"should have a secret", ^{
            model.secret = TEST_SECRET;
            model.secret should equal(TEST_SECRET);
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
            model = [OmniaPushBackEndRegistrationRequestData fromJsonData:nil error:&error];
            model should be_nil;
            error should_not be_nil;
            error.domain should equal(OmniaPushErrorDomain);
            error.code should equal(OmniaPushBackEndRegistrationRequestDataUnparseable);
        });
        
        it(@"should handle empty input", ^{
            model = [OmniaPushBackEndRegistrationRequestData fromJsonData:[NSData data] error:&error];
            model should be_nil;
            error should_not be_nil;
            error.domain should equal(OmniaPushErrorDomain);
            error.code should equal(OmniaPushBackEndRegistrationRequestDataUnparseable);
        });
        
        it(@"should handle bad JSON", ^{
            NSData *jsonData = [@"I AM NOT JSON" dataUsingEncoding:NSUTF8StringEncoding];
            model = [OmniaPushBackEndRegistrationRequestData fromJsonData:jsonData error:&error];
            model should be_nil;
            error should_not be_nil;
        });
        
        it(@"should construct a complete response object", ^{
            id dict = @{
                        kDeviceOS : TEST_OS,
                        kDeviceOSVersion : TEST_OS_VERSION,
                        kDeviceAlias : TEST_DEVICE_ALIAS,
                        kDeviceManufacturer : TEST_DEVICE_MANUFACTURER,
                        kDeviceModel : TEST_DEVICE_MODEL,
                        kReleaseUUID : TEST_RELEASE_UUID,
                        kReleaseSecret : TEST_SECRET,
                        kRegistrationToken : TEST_REGISTRATION_TOKEN,
                        };
            NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
            error should be_nil;
            data should_not be_nil;
            model = [OmniaPushBackEndRegistrationRequestData fromJsonData:data error:&error];
            model.os should equal(TEST_OS);
            model.osVersion should equal(TEST_OS_VERSION);
            model.deviceAlias should equal(TEST_DEVICE_ALIAS);
            model.deviceManufacturer should equal(TEST_DEVICE_MANUFACTURER);
            model.deviceModel should equal(TEST_DEVICE_MODEL);
            model.releaseUuid should equal(TEST_RELEASE_UUID);
            model.secret should equal(TEST_SECRET);
            model.registrationToken should equal(TEST_REGISTRATION_TOKEN);
        });
    });

    context(@"serialization", ^{
        
        __block NSDictionary *dict = nil;
        
        beforeEach(^{
            model = [[OmniaPushBackEndRegistrationRequestData alloc] init];
        });
        
        afterEach(^{
            dict = nil;
        });

        context(@"populated object", ^{
            
            beforeEach(^{
                model.releaseUuid = TEST_RELEASE_UUID;
                model.secret = TEST_SECRET;
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
                dict[kReleaseSecret] should equal(TEST_SECRET);
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
            
            it(@"should be jsonizable", ^{
                NSData *jsonData = [model toJsonData];
                jsonData should_not be_nil;
                NSError *error = nil;
                dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
                error should be_nil;
            });
        });
        
        context(@"unpopulated object", ^{
            
            afterEach(^{
                dict should_not be_nil;
                dict[kReleaseUUID] should be_nil;
                dict[kReleaseSecret] should be_nil;
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
            
            it(@"should be jsonizable", ^{
                NSData *jsonData = [model toJsonData];
                jsonData should_not be_nil;
                NSError *error = nil;
                dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
                error should be_nil;
            });
        });
    });
});

SPEC_END
