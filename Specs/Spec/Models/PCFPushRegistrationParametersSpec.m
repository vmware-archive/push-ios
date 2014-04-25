//
//  PCFPushRegistrationParametersSpec.mm
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//
#import <objc/runtime.h>

#import "Kiwi.h"
#import "PCFParameters.h"
#import "PCFClassPropertyUtility.h"

static NSString *const TEST_DEVICE_API_URL = @"http://testURL.com";
static NSString *const TEST_ANALYTICS_URL  = @"http://analyticsURL.com";
static NSString *const TEST_VARIANT_UUID   = @"SOS-WE-LIKE-IT-SPICY";
static NSString *const TEST_RELEASE_SECRET = @"Put sweet chili sauce on everything";
static NSString *const TEST_DEVICE_ALIAS   = @"Extreme spiciness classification";

SPEC_BEGIN(PCFPushRegistrationParametersSpec)

describe(@"PCFPushRegistrationParameters", ^{
    
    __block PCFParameters *model;

    afterEach(^{
        model = nil;
    });
    
    context(@"initializing with bad arguments programatically", ^{
        
        beforeEach(^{
            model = [PCFParameters parameters];
            [model setDeviceAlias:TEST_DEVICE_ALIAS];
            [model setPushAPIURL:TEST_DEVICE_API_URL];
            [model setAnalyticsAPIURL:TEST_ANALYTICS_URL];
            
            [model setDevelopmentReleaseSecret:TEST_RELEASE_SECRET];
            [model setProductionReleaseSecret:TEST_RELEASE_SECRET];
            
            [model setDevelopmentVariantUUID:TEST_VARIANT_UUID];
            [model setProductionVariantUUID:TEST_VARIANT_UUID];
        });
        
        it(@"should require all properties to be non-nil and non-empty", ^{
            [[theValue([model isValid]) should] beTrue];
            
            NSDictionary *properties = [PCFClassPropertyUtility propertiesForClass:[PCFParameters class]];
            [properties enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *propertyType, BOOL *stop) {
                
                //Primatives use single character property types.
                //https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
                if (propertyType.length > 1) {
                    id value = [model valueForKey:propertyName];
                    [model setValue:nil forKey:propertyName];
                    [[theValue([model isValid]) should] beFalse];
                    
                    [model setValue:@"" forKey:propertyName];
                    [[theValue([model isValid]) should] beFalse];
                    
                    [model setValue:value forKey:propertyName];
                    [[theValue([model isValid]) should] beTrue];
                }
            }];
        });
    });
    
    context(@"initializing with valid arguments from plist", ^{
        
        beforeEach(^{
            model = [PCFParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"PCFParameters-Valid" ofType:@"plist"]];
        });
        
        it(@"should be initialized successfully and valid", ^{
            [[model shouldNot] beNil];
            [[theValue([model isValid]) should] beTrue];
        });
    });

    context(@"initializing with invalid arguments from plist", ^{
       
        beforeEach(^{
            model = [PCFParameters parametersWithContentsOfFile:@"PCFParameters-Invalid.plist"];
        });
        
        it(@"should be initialized successfully and invalid", ^{
            [[model shouldNot] beNil];
            [[theValue([model isValid]) should] beFalse];
        });
    });
});

SPEC_END
