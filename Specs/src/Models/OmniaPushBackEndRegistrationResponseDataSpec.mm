#import "OmniaPushBackEndRegistrationResponseData.h"

#define TEST_REPLICANT_ID         @"123-456-789"
#define TEST_DEVICE_UUID          @"L337-L337-OH-YEAH"
#define TEST_DEVICE_ALIAS         @"l33t devices of badness"
#define TEST_DEVICE_MANUFACTURER  @"Amiga"
#define TEST_DEVICE_MODEL         @"500"
#define TEST_OS                   @"AmigaOS"
#define TEST_OS_VERSION           @"5.0"
#define TEST_REGISTRATION_TOKEN   @"ABC-DEF-GHI"

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
            model.replicantId should be_nil;
            model.deviceUuid should be_nil;
            model.deviceAlias should be_nil;
            model.deviceManufacturer should be_nil;
            model.deviceModel should be_nil;
            model.os should be_nil;
            model.osVersion should be_nil;
            model.registrationToken should be_nil;
        });
        
        it(@"should have a release_uuid", ^{
            model.replicantId = TEST_REPLICANT_ID;
            model.replicantId should equal(TEST_REPLICANT_ID);
        });
        
        it(@"should have a deviceUuid", ^{
            model.deviceUuid = TEST_DEVICE_UUID;
            model.deviceUuid should equal(TEST_DEVICE_UUID);
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
                model.replicantId = TEST_REPLICANT_ID;
                model.deviceUuid = TEST_DEVICE_UUID;
                model.deviceAlias = TEST_DEVICE_ALIAS;
                model.deviceManufacturer = TEST_DEVICE_MANUFACTURER;
                model.deviceModel = TEST_DEVICE_MODEL;
                model.os = TEST_OS;
                model.osVersion = TEST_OS_VERSION;
                model.registrationToken = TEST_REGISTRATION_TOKEN;
            });
            
            afterEach(^{
                dict should_not be_nil;
                dict[@"replicant_id"] should equal(TEST_REPLICANT_ID);
                dict[@"device_uuid"] should equal(TEST_DEVICE_UUID);
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
                dict[@"device_uuid"] should be_nil;
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
