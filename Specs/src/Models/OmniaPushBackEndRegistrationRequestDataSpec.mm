#import "OmniaPushBackEndRegistrationRequestData.h"
#import "OmniaPushErrors.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define TEST_RELEASE_UUID         @"123-456-789"
#define TEST_SECRET               @"My cat's breath smells like cat food"
#define TEST_DEVICE_ALIAS         @"l33t devices of badness"
#define TEST_DEVICE_MANUFACTURER  @"Commodore"
#define TEST_DEVICE_MODEL         @"64C"
#define TEST_OS                   @"BASIC"
#define TEST_OS_VERSION           @"2.0"
#define TEST_REGISTRATION_TOKEN   @"ABC-DEF-GHI"

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
                        @"os":TEST_OS,
                        @"os_version":TEST_OS_VERSION,
                        @"device_alias":TEST_DEVICE_ALIAS,
                        @"device_manufacturer":TEST_DEVICE_MANUFACTURER,
                        @"device_model":TEST_DEVICE_MODEL,
                        @"release_uuid":TEST_RELEASE_UUID,
                        @"secret":TEST_SECRET,
                        @"registration_token":TEST_REGISTRATION_TOKEN
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
                dict[@"release_uuid"] should equal(TEST_RELEASE_UUID);
                dict[@"secret"] should equal(TEST_SECRET);
                dict[@"device_alias"] should equal(TEST_DEVICE_ALIAS);
                dict[@"device_manufacturer"] should equal(TEST_DEVICE_MANUFACTURER);
                dict[@"device_model"] should equal(TEST_DEVICE_MODEL);
                dict[@"os"] should equal(TEST_OS);
                dict[@"os_version"] should equal(TEST_OS_VERSION);
                dict[@"registration_token"] should equal(TEST_REGISTRATION_TOKEN);
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
                dict[@"release_uuid"] should be_nil;
                dict[@"secret"] should be_nil;
                dict[@"device_alias"] should be_nil;
                dict[@"device_manufacturer"] should be_nil;
                dict[@"device_model"] should be_nil;
                dict[@"os"] should be_nil;
                dict[@"os_version"] should be_nil;
                dict[@"registration_token"] should be_nil;
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
