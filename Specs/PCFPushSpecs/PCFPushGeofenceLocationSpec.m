//
//  PCFPushGeofenceLocationSpec.m
//  PCFPushSpecs
//
//  Created by DX181-XL on 2015-04-14.
//
//

#import "Kiwi.h"
#import "PCFPushGeofenceLocation.h"
#import "PCFPushErrors.h"
#import "PCFPushSpecsHelper.h"
#import "NSObject+PCFJSONizable.h"

SPEC_BEGIN(PCFPushGeofenceLocationSpec)

describe(@"PCFPushGeofenceLocation", ^{
    
    __block PCFPushGeofenceLocation *model;
    __block PCFPushSpecsHelper *helper;
    
    beforeEach(^{
        helper = [[PCFPushSpecsHelper alloc] init];
        [helper setupParameters];
    });
    
    afterEach(^{
        model = nil;
    });
    
    it(@"should be initializable", ^{
        model = [[PCFPushGeofenceLocation alloc] init];
        [[model shouldNot] beNil];
    });
   
    context(@"fields", ^{

        beforeEach(^{
            model = [[PCFPushGeofenceLocation alloc] init];
        });
        
        it(@"should start as nil", ^{
            [[theValue(model.id) should] equal:theValue(0L)];
            [[model.name should] beNil];
            [[theValue(model.latitude) should] equal:theValue(0.0)];
            [[theValue(model.longitude) should] equal:theValue(0.0)];
            [[theValue(model.radius) should] equal:theValue(0.0)];
        });
        
        it(@"should have an ID", ^{
            model.id = TEST_GEOFENCE_ID;
            [[theValue(model.id) should] equal:theValue(TEST_GEOFENCE_ID)];
        });

        it(@"should have a name", ^{
            model.name = TEST_GEOFENCE_LOCATION_NAME;
            [[model.name should] equal:TEST_GEOFENCE_LOCATION_NAME];
        });

        it(@"should have a latitude", ^{
            model.latitude = TEST_GEOFENCE_LATITUDE;
            [[theValue(model.latitude) should] equal:theValue(TEST_GEOFENCE_LATITUDE)];
        });
        
        it(@"should have a longitude", ^{
            model.longitude = TEST_GEOFENCE_LONGITUDE;
            [[theValue(model.longitude) should] equal:theValue(TEST_GEOFENCE_LONGITUDE)];
        });
        
        it(@"should have a radius", ^{
            model.radius = TEST_GEOFENCE_RADIUS;
            [[theValue(model.radius) should] equal:theValue(TEST_GEOFENCE_RADIUS)];
        });
    });
    
    context(@"deserialization", ^{
        
        it(@"should handle a nil input", ^{
            NSError *error;
            model = [PCFPushGeofenceLocation pcf_fromJSONData:nil error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
            [[error.domain should] equal:PCFPushErrorDomain];
            [[theValue(error.code) should] equal:theValue(PCFPushBackEndDataUnparseable)];
        });
        
        it(@"should handle empty input", ^{
            NSError *error;
            model = [PCFPushGeofenceLocation pcf_fromJSONData:[NSData data] error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
            [[error.domain should] equal:PCFPushErrorDomain];
            [[theValue(error.code) should] equal:theValue(PCFPushBackEndDataUnparseable)];
        });
        
        it(@"should handle bad JSON", ^{
            NSError *error;
            NSData *JSONData = [@"I AM NOT JSON" dataUsingEncoding:NSUTF8StringEncoding];
            model = [PCFPushGeofenceLocation pcf_fromJSONData:JSONData error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
        });
        
        it(@"should construct a complete response object", ^{
            NSError *error;

            NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"geofence_location_1" ofType:@"json"];
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            
            [[data shouldNot] beNil];
            
            model = [PCFPushGeofenceLocation pcf_fromJSONData:data error:&error];
            [[error should] beNil];
            [[theValue(model.id) should] equal:theValue(TEST_GEOFENCE_ID)];
            [[model.name should] equal:TEST_GEOFENCE_LOCATION_NAME];
            [[theValue(model.latitude) should] equal:theValue(TEST_GEOFENCE_LATITUDE)];
            [[theValue(model.longitude) should] equal:theValue(TEST_GEOFENCE_LONGITUDE)];
            [[theValue(model.radius) should] equal:theValue(TEST_GEOFENCE_RADIUS)];
        });
    });
    
    context(@"serialization", ^{
        
        __block NSDictionary *dict = nil;
        
        beforeEach(^{
            model = [[PCFPushGeofenceLocation alloc] init];
        });
        
        afterEach(^{
            dict = nil;
        });
        
        context(@"populated object", ^{
            
            beforeEach(^{
                model.id = TEST_GEOFENCE_ID;
                model.name = TEST_GEOFENCE_LOCATION_NAME;
                model.latitude = TEST_GEOFENCE_LATITUDE;
                model.longitude = TEST_GEOFENCE_LONGITUDE;
                model.radius = TEST_GEOFENCE_RADIUS;
            });
            
            afterEach(^{
                [[dict shouldNot] beNil];
                [[dict[@"id"] should] equal:theValue(TEST_GEOFENCE_ID)];
                [[dict[@"name"] should] equal:TEST_GEOFENCE_LOCATION_NAME];
                [[dict[@"lat"] should] equal:theValue(TEST_GEOFENCE_LATITUDE)];
                [[dict[@"long"] should] equal:theValue(TEST_GEOFENCE_LONGITUDE)];
                [[dict[@"rad"] should] equal:theValue(TEST_GEOFENCE_RADIUS)];
            });
            
            it(@"should be dictionaryizable", ^{
                dict = [model pcf_toFoundationType];
            });
            
            it(@"should be JSONizable", ^{
                NSData *JSONData = [model pcf_toJSONData:nil];
                [[JSONData shouldNot] beNil];
                NSError *error = nil;
                dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
                [[error should] beNil];
            });
        });
        
        context(@"unpopulated object", ^{
            
            afterEach(^{
                [[dict shouldNot] beNil];
                [[dict[@"id"] should] equal:theValue(0L)];
                [[dict[@"name"] should] beNil];
                [[dict[@"lat"] should] equal:theValue(0.0)];
                [[dict[@"long"] should] equal:theValue(0.0)];
                [[dict[@"rad"] should] equal:theValue(0.0)];
            });
            
            it(@"should be dictionaryizable", ^{
                dict = [model pcf_toFoundationType];
            });
            
            it(@"should be JSONizable", ^{
                NSData *JSONData = [model pcf_toJSONData:nil];
                [[JSONData shouldNot] beNil];
                NSError *error = nil;
                dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
                [[error should] beNil];
            });
        });
    });
});

SPEC_END
