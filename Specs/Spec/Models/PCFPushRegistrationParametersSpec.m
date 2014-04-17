//
//  PCFPushRegistrationParametersSpec.mm
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//
#import <objc/runtime.h>

#import "Kiwi.h"
#import "PCFPushParameters.h"
#import "PCFClassPropertyUtility.h"

static NSString *const TEST_DEVICE_API_URL = @"http://testURL.com";
static NSString *const TEST_VARIANT_UUID   = @"SOS-WE-LIKE-IT-SPICY";
static NSString *const TEST_RELEASE_SECRET = @"Put sweet chili sauce on everything";
static NSString *const TEST_DEVICE_ALIAS   = @"Extreme spiciness classification";

SPEC_BEGIN(PCFPushRegistrationParametersSpec)

describe(@"PCFPushRegistrationParameters", ^{
    
    __block PCFPushParameters *model;

    afterEach(^{
        model = nil;
    });
    
    context(@"initializing with bad arguments programatically", ^{
        
        beforeEach(^{
            model = [PCFPushParameters parameters];
            [model setDeviceAlias:TEST_DEVICE_ALIAS];
            [model setDeviceAPIURL:TEST_DEVICE_API_URL];
            
            [model setDevelopmentReleaseSecret:TEST_RELEASE_SECRET];
            [model setProductionReleaseSecret:TEST_RELEASE_SECRET];
            
            [model setDevelopmentVariantUUID:TEST_VARIANT_UUID];
            [model setProductionVariantUUID:TEST_VARIANT_UUID];
        });
        
        it(@"should require all properties to be non-nil and non-empty", ^{
            [[theValue([model isValid]) should] beTrue];
            
            NSDictionary *properties = [PCFClassPropertyUtility propertiesForClass:[PCFPushParameters class]];
            [properties enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *propertyType, BOOL *stop) {
                id value = [model valueForKey:propertyName];
                [model setValue:nil forKey:propertyName];
                [[theValue([model isValid]) should] beFalse];
                
                [model setValue:@"" forKey:propertyName];
                [[theValue([model isValid]) should] beFalse];
                
                [model setValue:value forKey:propertyName];
                [[theValue([model isValid]) should] beTrue];
            }];
        });
    });
    
    context(@"initializing with valid arguments from plist", ^{
        
        beforeEach(^{
            model = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"PCFPushParameters-Valid" ofType:@"plist"]];
        });
        
        it(@"should be initialized successfully and valid", ^{
            [[model shouldNot] beNil];
            [[theValue([model isValid]) should] beTrue];
        });
    });

    context(@"initializing with invalid arguments from plist", ^{
       
        beforeEach(^{
            model = [PCFPushParameters parametersWithContentsOfFile:@"PCFPushParameters-Invalid.plist"];
        });
        
        it(@"should be initialized successfully and invalid", ^{
            [[model shouldNot] beNil];
            [[theValue([model isValid]) should] beFalse];
        });
    });
});

SPEC_END
