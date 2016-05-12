//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "Kiwi.h"
#import "PCFHardwareUtil.h"
#import "PCFPushParameters.h"
#import "PCFPushSpecsHelper.h"
#import "PCFClassPropertyUtility.h"
#import "PCFPushPersistentStorage.h"

SPEC_BEGIN(PCFPushParametersSpec)

void (^checkParametersAreValid)(PCFPushParameters *) = ^(PCFPushParameters *model) {
    NSDictionary *properties = [PCFClassPropertyUtility propertiesForClass:[PCFPushParameters class]];

    BOOL (^shouldTestProperty)(NSString *, NSString *) = ^BOOL(NSString *propertyName, NSString *propertyType) {

        // Primitives use single character property types.  Don't check those.
        // Also, don't check the validity of the tags, custom user ID, and alias parameters.  They are permitted to be nil or empty.
        // https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html

        if (propertyType.length <= 1) return NO;

        return !([propertyName isEqualToString:@"pushTags"] ||
                 [propertyName isEqualToString:@"pushDeviceAlias"] ||
                 [propertyName isEqualToString:@"areGeofencesEnabled"] ||
                 [propertyName isEqualToString:@"areAnalyticsEnabled"] ||
                 [propertyName isEqualToString:@"pushCustomUserId"] ||
                 [propertyName isEqualToString:@"pinnedSslCertificateNames"]);
    };

    [properties enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *propertyType, BOOL *stop) {

        if (shouldTestProperty(propertyName, propertyType)) {
            NSLog(@"Checking validity of property '%@', type '%@'", propertyName, propertyType);
            id value = [model valueForKey:propertyName];
            [model setValue:nil forKey:propertyName];

            BOOL (^valid)(PCFPushParameters *) = ^BOOL(PCFPushParameters *m) {
                return [m arePushParametersValid];
            };
            [[theValue(valid(model)) should] beFalse];

            [model setValue:@"" forKey:propertyName];
            [[theValue(valid(model)) should] beFalse];

            [model setValue:value forKey:propertyName];
            [[theValue(valid(model)) should] beTrue];
        } else {
            NSLog(@"Skipping validity check for property '%@', type '%@'", propertyName, propertyType);
        }
    }];
};

describe(@"PCFRegistrationParameters", ^{

    __block PCFPushSpecsHelper *helper = nil;
    __block PCFPushParameters *model;

    beforeEach(^{
        helper = [[PCFPushSpecsHelper alloc] init];
    });

    afterEach(^{
        model = nil;
        [helper reset];
    });

    context(@"initializing with bad arguments programatically", ^{

        beforeEach(^{
            model = [PCFPushParameters parameters];
            [model setPushTags:[NSSet<NSString*> setWithArray:@[@"TAG1", @"TAG2"]]];
            [model setPushDeviceAlias:TEST_DEVICE_ALIAS];
            [model setPushAPIURL:TEST_PUSH_API_URL_1];
            [model setPushCustomUserId:TEST_CUSTOM_USER_ID_1];
            [model setDevelopmentPushVariantSecret:TEST_VARIANT_SECRET];
            [model setProductionPushVariantSecret:TEST_VARIANT_SECRET];
            [model setDevelopmentPushVariantUUID:TEST_VARIANT_UUID];
            [model setProductionPushVariantUUID:TEST_VARIANT_UUID];
        });

        it(@"should require all push properties (except tags, device alias, custom user ID, and geofences enabled) to be non-nil and non-empty", ^{
            [[theValue([model arePushParametersValid]) should] beTrue];
            checkParametersAreValid(model);
        });

        it(@"should allow the custom user ID to be nil", ^{
            model.pushCustomUserId = nil;
            [[theValue([model arePushParametersValid]) should] beTrue];
        });

        it(@"should allow the custom user ID to be empty", ^{
            model.pushCustomUserId = @"";
            [[theValue([model arePushParametersValid]) should] beTrue];
        });

        it(@"should allow the device alias to be nil", ^{
            model.pushDeviceAlias = nil;
            [[theValue([model arePushParametersValid]) should] beTrue];
        });

        it(@"should allow the device alias to be empty", ^{
            model.pushDeviceAlias = @"";
            [[theValue([model arePushParametersValid]) should] beTrue];
        });

        it(@"should allow the tags to be nil", ^{
            model.pushTags = nil;
            [[theValue([model arePushParametersValid]) should] beTrue];
        });

        it(@"should allow the tags to be empty", ^{
            model.pushTags = [NSSet<NSString*> set];
            [[theValue([model arePushParametersValid]) should] beTrue];
        });

        it(@"should allow custom user IDs with length 254", ^{
            model.pushCustomUserId = stringWithLength(254);
            [[model.pushCustomUserId should] haveLengthOf:254];
            [[theValue([model arePushParametersValid]) should] beTrue];
        });

        it(@"should allow custom user IDs with length 255", ^{
            model.pushCustomUserId = stringWithLength(255);
            [[model.pushCustomUserId should] haveLengthOf:255];
            [[theValue([model arePushParametersValid]) should] beTrue];
        });

        it(@"should allow custom user IDs with length 256", ^{
            model.pushCustomUserId = stringWithLength(256);
            [[model.pushCustomUserId should] haveLengthOf:256];
            [[theValue([model arePushParametersValid]) should] beFalse];
        });
    });

    context(@"initializing from the default plist file", ^{

       beforeEach(^{
           [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
           model = [PCFPushParameters defaultParameters];
       });

        it(@"should initialize successfully and indicate that parameters are valid", ^{
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[model.pushAPIURL should] equal:@"http://test.url.com"];
            [[model.developmentPushVariantSecret should] equal:@"No secret is as strong as its blabbiest keeper"];
            [[model.developmentPushVariantUUID should] equal:@"444-555-666-777"];
            [[model.productionPushVariantSecret should] equal:@"No secret is as strong as its blabbiest keeper"];
            [[model.productionPushVariantUUID should] equal:@"444-555-666-777"];
            [[model.pushDeviceAlias should] beNil];
            [[model.pushCustomUserId should] beNil];
            [[model.pushTags should] beNil];
            [[theValue(model.areGeofencesEnabled) should] beFalse];
            [[theValue(model.areAnalyticsEnabled) should] beTrue];
            [[model.pinnedSslCertificateNames should] containObjectsInArray:@[ @"certificate.der", @"DOGS", @"CATS" ]];
            [[theValue(model.sslCertValidationMode) should] equal:theValue(PCFPushSslCertValidationModeSystemDefault)];
        });
    });

    context(@"initializing with valid arguments from plist", ^{

        beforeEach(^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-Valid" ofType:@"plist"]];
        });

        it(@"should initialize successfully and indicate that parameters are valid", ^{
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beTrue];
        });
    });

    context(@"parsing SSL certificate validation mode settings", ^{

        it(@"should parse 'default'", ^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-Valid" ofType:@"plist"]];
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[theValue(model.sslCertValidationMode) should] equal:theValue(PCFPushSslCertValidationModeSystemDefault)];
        });

        it(@"should parse 'callback'", ^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-SslCallback" ofType:@"plist"]];
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[theValue(model.sslCertValidationMode) should] equal:theValue(PCFPushSslCertValidationModeCustomCallback)];
        });

        it(@"should parse 'trustall'", ^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-SslTrustAll" ofType:@"plist"]];
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[theValue(model.sslCertValidationMode) should] equal:theValue(PCFPushSslCertValidationModeTrustAll)];
        });

        it(@"should parse 'pinned'", ^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-SslPinned" ofType:@"plist"]];
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[theValue(model.sslCertValidationMode) should] equal:theValue(PCFPushSslCertValidationModePinned)];
        });

        it(@"should use 'default' as a default", ^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-SslEmpty" ofType:@"plist"]];
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[theValue(model.sslCertValidationMode) should] equal:theValue(PCFPushSslCertValidationModeSystemDefault)];
        });

        it(@"should throw an error if the setting is invalid", ^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-SslInvalidValue" ofType:@"plist"]];
            [[model should] beNil];
        });
    });

    context(@"SSL pinning", ^{

        it(@"should require a list of pinned SSL certificates if using 'pinned' certificate mode", ^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-MissingPinnedCertificates" ofType:@"plist"]];
            [[model shouldNot] beNil];
            [[theValue(model.sslCertValidationMode) should] equal:theValue(PCFPushSslCertValidationModePinned)];
            [[model.pinnedSslCertificateNames should] beNil];
            [[theValue([model arePushParametersValid]) should] beNo];
        });
    });

    context(@"reading the areGeofencesEnabled value", ^{

        it(@"should initialize successfully and indicate that parameters are valid if areGeofencesEnabled is true", ^{
            [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
            [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
            model = [PCFPushParameters defaultParameters];
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[theValue(model.areGeofencesEnabled) should] beYes];
        });
    });

    context(@"reading the areAnalyticsEnabled value", ^{

        it(@"should initialize successfully and indicate that parameters are valid if areAnalyticsEnabled is false", ^{
            [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-AnalyticsDisabled" ofType:@"plist"]];
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[theValue(model.areAnalyticsEnabled) should] beNo];
        });
    });

    context(@"initializing with invalid arguments from plist", ^{

        it(@"should load but indicate that parameters are invalid", ^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-Invalid" ofType:@"plist"]];
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beFalse];
        });

        it(@"should require the trustPinnedCertificates parameter to be an array, if present", ^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-BadPinnedCertificate" ofType:@"plist"]];
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beFalse];
        });
    });

    context(@"ignoring the tags, custom user ID and device alias parameters from plist", ^{
        beforeEach(^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-ExtraParameters" ofType:@"plist"]];
        });

        it(@"should ignore the custom user ID in the plist", ^{
            [[model.pushCustomUserId should] beNil];
        });

        it(@"should ignore the device alias in the plist", ^{
            [[model.pushDeviceAlias should] beNil];
        });

        it(@"should ignore the tags in the plist", ^{
            [[model.pushTags should] beNil];
        });
    });

    context(@"reading the provisioning profile", ^{

        beforeEach(^{
            pcfPushResetOnceToken();
        });

        it(@"should detect simulators", ^{
            [PCFHardwareUtil stub:@selector(isSimulator) andReturn:theValue(YES)];
            [NSData stub:@selector(dataWithContentsOfFile:) andReturn:nil];
            [[theValue(pcfPushIsAPNSSandbox()) should] beTrue];
        });

        it(@"should detect sandbox builds", ^{
            [PCFHardwareUtil stub:@selector(isSimulator) andReturn:theValue(NO)];
            NSData *sandboxProvisioningFileExcerpt = [@"<key>aps-environment</key><string>development</string>" dataUsingEncoding:NSUTF8StringEncoding];
            [NSData stub:@selector(dataWithContentsOfFile:) andReturn:sandboxProvisioningFileExcerpt];
            [[theValue(pcfPushIsAPNSSandbox()) should] beTrue];
        });

        it(@"should detect production builds", ^{
            [PCFHardwareUtil stub:@selector(isSimulator) andReturn:theValue(NO)];
            NSData *productionProvisioningFileExcerpt = [@"<key>aps-environment</key><string>production</string>" dataUsingEncoding:NSUTF8StringEncoding];
            [NSData stub:@selector(dataWithContentsOfFile:) andReturn:productionProvisioningFileExcerpt];
            [[theValue(pcfPushIsAPNSSandbox()) should] beFalse];
        });
    });

    context(@"are analytics available", ^{

        it(@"analytics are not available if the PLIST parameter is no", ^{
            [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-AnalyticsDisabled" ofType:@"plist"]];
            [[theValue(model.areAnalyticsEnabledAndAvailable) should] beNo];
        });

        context(@"the areAnalyticsAvailable=YES in the PLIST", ^{

            beforeEach(^{
                [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
                model = [PCFPushParameters defaultParameters];
            });

            it(@"analytics are not available if the server version is not set", ^{
                [[theValue(model.areAnalyticsEnabledAndAvailable) should] beNo];
            });

            it(@"analytics are not available if the server version is old", ^{
                [PCFPushPersistentStorage setServerVersion:@"1.3.1"];
                [[theValue(model.areAnalyticsEnabledAndAvailable) should] beNo];
            });

            it(@"analytics are not available if the server version is current", ^{
                [PCFPushPersistentStorage setServerVersion:@"1.3.2"];
                [[theValue(model.areAnalyticsEnabledAndAvailable) should] beYes];
            });

            it(@"analytics are not available if the server version is newer", ^{
                [PCFPushPersistentStorage setServerVersion:@"1.3.3"];
                [[theValue(model.areAnalyticsEnabledAndAvailable) should] beYes];
            });
        });
    });
    
    context(@"overriding properties", ^{
        
        beforeEach(^{
            [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
        });

        it(@"should let you override the pushAPIURL parameter", ^{
            [[NSUserDefaults standardUserDefaults] setValue:@"CATS" forKey:@"override.pivotal.push.serviceUrl"];
            model = [PCFPushParameters defaultParameters];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[model.pushAPIURL should] equal:@"CATS"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"override.pivotal.push.serviceUrl"];
        });
        
        it(@"should let you override the model.developmentPushVariantSecret parameter", ^{
            [[NSUserDefaults standardUserDefaults] setValue:@"PARROTS" forKey:@"override.pivotal.push.platformSecretDevelopment"];
            model = [PCFPushParameters defaultParameters];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[model.developmentPushVariantSecret should] equal:@"PARROTS"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"override.pivotal.push.platformSecretDevelopment"];
        });
        
        it(@"should let you override the model.productionPushVariantSecret parameter", ^{
            [[NSUserDefaults standardUserDefaults] setValue:@"CACTUS" forKey:@"override.pivotal.push.platformSecretProduction"];
            model = [PCFPushParameters defaultParameters];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[model.productionPushVariantSecret should] equal:@"CACTUS"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"override.pivotal.push.platformSecretProduction"];
        });
        
        it(@"should let you override the model.developmentPushVariantUUID parameter", ^{
            [[NSUserDefaults standardUserDefaults] setValue:@"MONKEYS" forKey:@"override.pivotal.push.platformUuidDevelopment"];
            model = [PCFPushParameters defaultParameters];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[model.developmentPushVariantUUID should] equal:@"MONKEYS"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"override.pivotal.push.platformUuidDevelopment"];
        });
        
        it(@"should let you override the model.productionPushVariantUUID parameter", ^{
            [[NSUserDefaults standardUserDefaults] setValue:@"BANANAS" forKey:@"override.pivotal.push.platformUuidProduction"];
            model = [PCFPushParameters defaultParameters];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[model.productionPushVariantUUID should] equal:@"BANANAS"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"override.pivotal.push.platformUuidProduction"];
        });
        
        it(@"should let you override the model.areAnalyticsEnabled parameter", ^{
            [[NSUserDefaults standardUserDefaults] setValue:@"NO" forKey:@"override.pivotal.push.areAnalyticsEnabled"];
            model = [PCFPushParameters defaultParameters];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[theValue([model areAnalyticsEnabled]) should] beNo];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"override.pivotal.push.areAnalyticsEnabled"];
        });
        
        it(@"should let you override the model.sslCertValidationMode parameter", ^{
            [[NSUserDefaults standardUserDefaults] setValue:@"pinned" forKey:@"override.pivotal.push.sslCertValidationMode"];
            model = [PCFPushParameters defaultParameters];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[theValue(model.sslCertValidationMode) should] equal:theValue(PCFPushSslCertValidationModePinned)];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"override.pivotal.push.sslCertValidationMode"];
        });
        
        it(@"should let you override the model.pinnedSslCertificateNames parameter", ^{
            [[NSUserDefaults standardUserDefaults] setValue:@"FUZZY BUNNY ELBOW DROP" forKey:@"override.pivotal.push.pinnedSslCertificateNames"];
            model = [PCFPushParameters defaultParameters];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[model.pinnedSslCertificateNames should] containObjectsInArray:@[@"FUZZY", @"BUNNY", @"ELBOW", @"DROP"]];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"override.pivotal.push.pinnedSslCertificateNames"];
        });
    });
});

SPEC_END
