//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "Kiwi.h"
#import "MSSParameters.h"
#import "MSSClassPropertyUtility.h"

static NSString *const TEST_DEVICE_API_URL = @"http://testURL.com";
static NSString *const TEST_ANALYTICS_URL  = @"http://analyticsURL.com";
static NSString *const TEST_VARIANT_UUID   = @"SOS-WE-LIKE-IT-SPICY";
static NSString *const TEST_VARIANT_SECRET = @"Put sweet chili sauce on everything";
static NSString *const TEST_DEVICE_ALIAS   = @"Extreme spiciness classification";

static NSString *const TEST_ANALYTICS_KEY   = @"TEST_ANALYTICS_KEY";

SPEC_BEGIN(MSSRegistrationParametersSpec)

void (^checkParametersAreValid)(MSSParameters *) = ^(MSSParameters *model) {
    NSDictionary *properties = [MSSClassPropertyUtility propertiesForClass:[MSSParameters class]];

    [properties enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *propertyType, BOOL *stop) {
        
        //Primitives use single character property types.  Don't check those.
        // Also, don't check the validity of the tags parameter.  It is permitted to be nil.
        //https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
        
        if (![propertyName isEqualToString:@"pushTags"] && propertyType.length > 1) {
            NSLog(@"Checking validity of property '%@', type '%@'", propertyName, propertyType);
            id value = [model valueForKey:propertyName];
            [model setValue:nil forKey:propertyName];
            
            BOOL (^valid)(MSSParameters *) = ^BOOL(MSSParameters *model) {
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

describe(@"MSSRegistrationParameters", ^{
    
    __block MSSParameters *model;

    afterEach(^{
        model = nil;
    });
    
    context(@"initializing with bad arguments programatically", ^{
        
        beforeEach(^{
            model = [MSSParameters parameters];
            [model setPushDeviceAlias:TEST_DEVICE_ALIAS];
            [model setPushAPIURL:TEST_DEVICE_API_URL];
            
            [model setDevelopmentPushVariantSecret:TEST_VARIANT_SECRET];
            [model setProductionPushVariantSecret:TEST_VARIANT_SECRET];
            
            [model setDevelopmentPushVariantUUID:TEST_VARIANT_UUID];
            [model setProductionPushVariantUUID:TEST_VARIANT_UUID];
        });
        
        it(@"should require all push properties (except tags) to be non-nil and non-empty", ^{
            [[theValue([model arePushParametersValid]) should] beTrue];
            checkParametersAreValid(model);
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
    
    context(@"initializing with valid arguments from plist", ^{
        
        beforeEach(^{
            model = [MSSParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"MSSParameters-Valid" ofType:@"plist"]];
        });
        
        it(@"push Parameters should be initialized successfully and valid", ^{
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beTrue];
        });
    });

    context(@"initializing with invalid arguments from plist", ^{
       
        beforeEach(^{
            model = [MSSParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"MSSParameters-Invalid" ofType:@"plist"]];
        });
        
        it(@"push Parameters should be initialized successfully and invalid", ^{
            [[model shouldNot] beNil];
            [[theValue([model arePushParametersValid]) should] beFalse];
        });
    });
});

SPEC_END
