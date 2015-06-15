//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "Kiwi.h"
#import "PCFPushParameters.h"
#import "PCFClassPropertyUtility.h"
#import "PCFPushSpecsHelper.h"
#import "PCFHardwareUtil.h"

SPEC_BEGIN(PCFRegistrationParametersSpec)

void (^checkParametersAreValid)(PCFPushParameters *) = ^(PCFPushParameters *model) {
    NSDictionary *properties = [PCFClassPropertyUtility propertiesForClass:[PCFPushParameters class]];

    BOOL (^shouldTestProperty)(NSString *, NSString *) = ^BOOL(NSString *propertyName, NSString *propertyType) {

        // Primitives use single character property types.  Don't check those.
        // Also, don't check the validity of the tags and alias parameters.  They are permitted to be nil or empty.
        // https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html

        if (propertyType.length < 1) return NO;

        return !([propertyName isEqualToString:@"pushTags"] ||
                 [propertyName isEqualToString:@"pushDeviceAlias"] ||
                 [propertyName isEqualToString:@"areGeofencesEnabled"] ||
                 [propertyName isEqualToString:@"trustAllSslCertificates"]);
    };

    [properties enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *propertyType, BOOL *stop) {

        if (shouldTestProperty(propertyName, propertyType)) {
            NSLog(@"Checking validity of property '%@', type '%@'", propertyName, propertyType);
            id value = [model valueForKey:propertyName];
            [model setValue:nil forKey:propertyName];

            BOOL (^valid)(PCFPushParameters *) = ^BOOL(PCFPushParameters *model) {
                return [model arePushParametersValid];
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
            [model setPushTags:[NSSet setWithArray:@[@"TAG1", @"TAG2"]]];
            [model setPushDeviceAlias:TEST_DEVICE_ALIAS];
            [model setPushAPIURL:TEST_PUSH_API_URL_1];
            [model setDevelopmentPushVariantSecret:TEST_VARIANT_SECRET];
            [model setProductionPushVariantSecret:TEST_VARIANT_SECRET];
            [model setDevelopmentPushVariantUUID:TEST_VARIANT_UUID];
            [model setProductionPushVariantUUID:TEST_VARIANT_UUID];
        });

        it(@"should require all push properties (except tags, device alias, trustAllSslCertificates, and geofences enabled) to be non-nil and non-empty", ^{
            [[theValue([model arePushParametersValid]) should] beTrue];
            checkParametersAreValid(model);
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
            model.pushTags = [NSSet set];
            [[theValue([model arePushParametersValid]) should] beTrue];
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
            [[model.pushTags should] beNil];
            [[theValue(model.areGeofencesEnabled) should] beYes];
            [[theValue(model.trustAllSslCertificates) should] beFalse];
        });
    });

    context(@"initializing with valid arguments from plist", ^{

        beforeEach(^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-Valid" ofType:@"plist"]];
        });

        it(@"should initialize successfully and indicate that parameters are valid", ^{
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[theValue(model.trustAllSslCertificates) should] beTrue];
        });
    });

    context(@"reading the areGeofencesEnabled value", ^{

        it(@"should initialize successfully and indicate that parameters are valid if areGeofencesEnabled is false", ^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-GeofencesDisabled" ofType:@"plist"]];
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beTrue];
            [[theValue(model.areGeofencesEnabled) should] beNo];
        });
    });

    context(@"initializing with invalid arguments from plist", ^{

        beforeEach(^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-Invalid" ofType:@"plist"]];
        });

        it(@"should load but indicate that parameters are invalid", ^{
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beFalse];
        });
    });

    context(@"ignoring the tags and device alias parameters from plist", ^{
        beforeEach(^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-ExtraParameters" ofType:@"plist"]];
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
});

SPEC_END
