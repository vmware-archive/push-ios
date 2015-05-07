//
//  PCFPushGeofenceDataSpec.m
//  PCFPushSpecs
//
//  Created by DX181-XL on 2015-04-14.
//
//

#import "Kiwi.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushErrors.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushGeofenceLocation.h"

SPEC_BEGIN(PCFPushGeofenceDataSpec)

describe(@"PCFPushGeofenceData", ^{
    
    __block PCFPushGeofenceData *model;
    __block PCFPushSpecsHelper *helper;
    
    beforeEach(^{
        helper = [[PCFPushSpecsHelper alloc] init];
        [helper setupParameters];
    });
    
    afterEach(^{
        model = nil;
    });
    
    it(@"should be initializable", ^{
        model = [[PCFPushGeofenceData alloc] init];
        [[model shouldNot] beNil];
    });
   
    context(@"fields", ^{

        beforeEach(^{
            model = [[PCFPushGeofenceData alloc] init];
        });
        
        it(@"should start as nil", ^{
            [[theValue(model.id) should] beZero];
            [[model.tags should] beNil];
            [[model.data should] beNil];
            [[model.expiryTime should] beNil];
            [[model.locations should] beNil];
            [[theValue(model.triggerType) should] equal:theValue(PCFPushTriggerTypeUndefined)];
        });
        
        it(@"should have an ID", ^{
            model.id = TEST_GEOFENCE_ID;
            [[theValue(model.id) should] equal:theValue(TEST_GEOFENCE_ID)];
        });
        
        it(@"should have an expiry time", ^{
            model.expiryTime = helper.testGeofenceDate;
            [[model.expiryTime should] equal:helper.testGeofenceDate];
        });
        
        it(@"should have tags", ^{
            model.tags = helper.tags1;
            [[model.tags should] equal:helper.tags1];
        });
        
        it(@"should have a list of locations", ^{

            PCFPushGeofenceLocation *location1 = [[PCFPushGeofenceLocation alloc] init];
            location1.id = 66L;

            PCFPushGeofenceLocation *location2 = [[PCFPushGeofenceLocation alloc] init];
            location2.id = 784L;
            NSArray *arr = @[location1, location2];

            model.locations = arr;
            [[model.locations should] equal:arr];
        });

        it(@"should have a trigger type", ^{
            model.triggerType = PCFPushTriggerTypeExit;
            [[theValue(model.triggerType) should] equal:theValue(PCFPushTriggerTypeExit)];
        });
    });

    context(@"deserialization", ^{
        
        it(@"should handle a nil input", ^{
            NSError *error;
            model = [PCFPushGeofenceData pcf_fromJSONData:nil error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
            [[error.domain should] equal:PCFPushErrorDomain];
            [[theValue(error.code) should] equal:theValue(PCFPushBackEndDataUnparseable)];
        });
        
        it(@"should handle empty input", ^{
            NSError *error;
            model = [PCFPushGeofenceData pcf_fromJSONData:[NSData data] error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
            [[error.domain should] equal:PCFPushErrorDomain];
            [[theValue(error.code) should] equal:theValue(PCFPushBackEndDataUnparseable)];
        });
        
        it(@"should handle bad JSON", ^{
            NSError *error;
            NSData *JSONData = [@"I AM NOT JSON" dataUsingEncoding:NSUTF8StringEncoding];
            model = [PCFPushGeofenceData pcf_fromJSONData:JSONData error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
        });
        
        it(@"should construct a complete response object", ^{
            NSError *error;
            NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"geofence_with_locations_1" ofType:@"json"];
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            
            [[data shouldNot] beNil];
            
            model = [PCFPushGeofenceData pcf_fromJSONData:data error:&error];
            [[error should] beNil];
            
            [[theValue(model.id) should] equal:theValue(7L)];
            [[model.data should] equal:@{ @"message":@"tacos" }];
            [[model.expiryTime should] equal:[NSDate dateWithTimeIntervalSince1970:1424309210.305]];
            [[theValue(model.triggerType) should] equal:theValue(PCFPushTriggerTypeEnter)];
            [[model.locations should] haveCountOf:3];

            [[theValue(((PCFPushGeofenceLocation*)(model.locations[0])).id) should] equal:theValue(66L)];
            [[theValue(((PCFPushGeofenceLocation*)(model.locations[1])).id) should] equal:theValue(82L)];
            [[theValue(((PCFPushGeofenceLocation*)(model.locations[2])).id) should] equal:theValue(88L)];
        });

        it(@"should handle deserializing expiry times", ^{
            model = [PCFPushGeofenceData pcf_fromDictionary:@{ @"expiry_time" : @0 } ];
            [[model.expiryTime should] equal:[NSDate dateWithTimeIntervalSince1970:0.0]];

            model = [PCFPushGeofenceData pcf_fromDictionary:@{ @"expiry_time" : @10 } ];
            [[model.expiryTime should] equal:[NSDate dateWithTimeIntervalSince1970:0.010]];

            model = [PCFPushGeofenceData pcf_fromDictionary:@{ @"expiry_time" : @1000 } ];
            [[model.expiryTime should] equal:[NSDate dateWithTimeIntervalSince1970:1.0]];

            model = [PCFPushGeofenceData pcf_fromDictionary:@{ @"expiry_time" : [NSNull null] } ];
            [[model.expiryTime should] beNil];

            model = [PCFPushGeofenceData pcf_fromDictionary:@{ } ];
            [[model.expiryTime should] beNil];
        });

        it(@"should handle deserializing all the trigger types", ^{
            model = [PCFPushGeofenceData pcf_fromDictionary: @{ @"trigger_type" : @"enter" } ];
            [[theValue(model.triggerType) should] equal:theValue(PCFPushTriggerTypeEnter)];

            model = [PCFPushGeofenceData pcf_fromDictionary: @{ @"trigger_type" : @"exit" } ];
            [[theValue(model.triggerType) should] equal:theValue(PCFPushTriggerTypeExit)];

            model = [PCFPushGeofenceData pcf_fromDictionary: @{ @"trigger_type" : @"enter_or_exit" } ];
            [[theValue(model.triggerType) should] equal:theValue(PCFPushTriggerTypeEnterOrExit)];

            model = [PCFPushGeofenceData pcf_fromDictionary: @{ @"trigger_type" : @"not_a_trigger_type" } ];
            [[theValue(model.triggerType) should] equal:theValue(PCFPushTriggerTypeUndefined)];

            model = [PCFPushGeofenceData pcf_fromDictionary: @{ @"trigger_type" : @"" } ];
            [[theValue(model.triggerType) should] equal:theValue(PCFPushTriggerTypeUndefined)];

            model = [PCFPushGeofenceData pcf_fromDictionary: @{ @"trigger_type" : [NSNull null] } ];
            [[theValue(model.triggerType) should] equal:theValue(PCFPushTriggerTypeUndefined)];

            model = [PCFPushGeofenceData pcf_fromDictionary: @{  } ];
            [[theValue(model.triggerType) should] equal:theValue(PCFPushTriggerTypeUndefined)];
        });

        it(@"should handle deserializing locations", ^{
            model = [PCFPushGeofenceData pcf_fromDictionary: @{ @"locations" : [NSNull null] } ];
            [[model.locations should] beNil];

            model = [PCFPushGeofenceData pcf_fromDictionary: @{ @"locations" : @[] } ];
            [[model.locations should] beNil];

            model = [PCFPushGeofenceData pcf_fromDictionary: @{ @"locations" : @[ @{@"id":@99L} ] } ];
            [[model.locations should] haveCountOf:1];
            [[theValue(((PCFPushGeofenceLocation *)(model.locations[0])).id) should] equal:theValue(99L)];
        });

        it(@"should handle deserializing tags", ^{

            model = [PCFPushGeofenceData pcf_fromDictionary:@{ @"tags" : [NSNull null] } ];
            [[model.tags should] beNil];

            model = [PCFPushGeofenceData pcf_fromDictionary:@{ @"tags" : @[] } ];
            [[model.tags should] beNil];

            model = [PCFPushGeofenceData pcf_fromDictionary:@{ @"tags" : @[ @"TAG1" ] } ];
            [[model.tags should] equal:[NSSet setWithArray:@[ @"TAG1" ] ] ];

            model = [PCFPushGeofenceData pcf_fromDictionary:@{ @"tags" : @[ @"TAG2", @"TAG3"] } ];
            [[model.tags should] equal:[NSSet setWithArray:@[ @"TAG2", @"TAG3" ] ] ];
        });
    });
    
    context(@"serialization", ^{

        __block NSDictionary *dict = nil;
        __block PCFPushGeofenceLocation *location1;
        __block PCFPushGeofenceLocation *location2;

        beforeEach(^{
            model = [[PCFPushGeofenceData alloc] init];
        });

        afterEach(^{
            dict = nil;
        });

        context(@"populated object", ^{

            beforeEach(^{
                model.id = TEST_GEOFENCE_ID;
                model.data = @{ @"message":@"tacos" };
                model.triggerType = PCFPushTriggerTypeEnterOrExit;
                model.expiryTime = [NSDate dateWithTimeIntervalSince1970:1000.0];

                location1 = [[PCFPushGeofenceLocation alloc] init];
                location1.id = 66L;

                location2 = [[PCFPushGeofenceLocation alloc] init];
                location2.id = 784L;

                model.locations = @[ location1, location2 ];

                model.tags = [NSSet setWithArray:@[ @"PETE", @"REPEAT" ]];
            });

            afterEach(^{
                [[dict shouldNot] beNil];
                [[dict[@"id"] should] equal:theValue(TEST_GEOFENCE_ID)];
                [[dict[@"data"] should] equal:@{ @"message":@"tacos" }];
                [[dict[@"trigger_type"] should] equal:@"enter_or_exit"];
                [[dict[@"expiry_time"] should] equal:@1000000];
                [[dict[@"locations"] should] haveCountOf:2];
                [[dict[@"locations"][0][@"id"] should] equal:@66L];
                [[dict[@"locations"][1][@"id"] should] equal:@784L];
                [[dict[@"tags"] should] containObjectsInArray:@[ @"PETE", @"REPEAT" ]];
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
                [[dict[@"id"] should] beZero];
                [[dict[@"data"] should] beNil];
                [[dict[@"trigger_type"] should] beNil];
                [[dict[@"expiry_time"] should] beNil];
                [[dict[@"locations"] should] beNil];
                [[dict[@"tags"] should] beNil];
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

        context(@"serializing individual fields", ^{

            it(@"should serialize various trigger types", ^{
                model.triggerType = PCFPushTriggerTypeUndefined;
                dict = [model pcf_toFoundationType];
                [[dict[@"trigger_type"] should] beNil];

                model.triggerType = PCFPushTriggerTypeEnter;
                dict = [model pcf_toFoundationType];
                [[dict[@"trigger_type"] should] equal:@"enter"];

                model.triggerType = PCFPushTriggerTypeExit;
                dict = [model pcf_toFoundationType];
                [[dict[@"trigger_type"] should] equal:@"exit"];

                model.triggerType = PCFPushTriggerTypeEnterOrExit;
                dict = [model pcf_toFoundationType];
                [[dict[@"trigger_type"] should] equal:@"enter_or_exit"];
            });

            it(@"should serialize various expiry times", ^{
                model.expiryTime = nil;
                dict = [model pcf_toFoundationType];
                [[dict[@"expiry_time"] should] beNil];

                model.expiryTime = (NSDate*)(id)[NSNull null];
                dict = [model pcf_toFoundationType];
                [[dict[@"expiry_time"] should] beNil];

                model.expiryTime = [NSDate dateWithTimeIntervalSince1970:0];
                dict = [model pcf_toFoundationType];
                [[dict[@"expiry_time"] should] beZero];

                model.expiryTime = [NSDate dateWithTimeIntervalSince1970:0.10];
                dict = [model pcf_toFoundationType];
                [[dict[@"expiry_time"] should] equal:@100L];

                model.expiryTime = [NSDate dateWithTimeIntervalSince1970:1000];
                dict = [model pcf_toFoundationType];
                [[dict[@"expiry_time"] should] equal:@1000000L];
            });

            it(@"should serialize list of locations", ^{
                model.locations = nil;
                dict = [model pcf_toFoundationType];
                [[dict[@"locations"] should] beNil];

                model.locations = (NSArray*)(id)[NSNull null];
                dict = [model pcf_toFoundationType];
                [[dict[@"locations"] should] beNil];

                model.locations = @[];
                dict = [model pcf_toFoundationType];
                [[dict[@"locations"] should] beNil];
            });

            it(@"should serialize tags", ^{
                model.tags = nil;
                dict = [model pcf_toFoundationType];
                [[dict[@"tags"] should] beNil];

                model.tags = (NSSet*)(id)[NSNull null];
                dict = [model pcf_toFoundationType];
                [[dict[@"tags"] should] beNil];

                model.tags = [NSSet set];
                dict = [model pcf_toFoundationType];
                [[dict[@"tags"] should] beNil];

                model.tags = [NSSet setWithObject:@"CACTUS"];
                dict = [model pcf_toFoundationType];
                [[dict[@"tags"] should] equal:@[@"CACTUS"]];

                model.tags = [NSSet setWithArray:@[@"SNAKES", @"TUMBLEWEED", @"SAND", @"ROCKS"]];
                dict = [model pcf_toFoundationType];
                [[dict[@"tags"] should] containObjectsInArray:@[@"SNAKES", @"TUMBLEWEED", @"SAND", @"ROCKS"]];
            });
        });
    });

    context(@"object comparison", ^{

        it(@"should be able to compare two objects with isEqual", ^{

            PCFPushGeofenceLocation *location1 = [[PCFPushGeofenceLocation alloc] init];
            location1.id = 55;
            location1.name = [@"CHURROS " stringByAppendingString:@"LOCATION"];
            location1.latitude = 80.5;
            location1.longitude = -40.5;
            location1.radius = 160.5;

            PCFPushGeofenceLocation *location2 = [[PCFPushGeofenceLocation alloc] init];
            location2.id = 55;
            location2.name = [NSString stringWithFormat:@"%@ LOC%@", @"CHURROS", @"ATION"];
            location2.latitude = 80.5;
            location2.longitude = -40.5;
            location2.radius = 160.5;

            PCFPushGeofenceData *data1 = [[PCFPushGeofenceData alloc] init];
            data1.id = 10;
            data1.expiryTime = [NSDate dateWithTimeIntervalSince1970:1000.0];
            data1.tags = [NSSet setWithArray:@[@"TAG1", @"TAG2"]];
            data1.data = @{ @"CAT" : @"PRETTY" };
            data1.triggerType = PCFPushTriggerTypeEnterOrExit;
            data1.locations = @[ location1 ];


            PCFPushGeofenceData *data2 = [[PCFPushGeofenceData alloc] init];
            data2.id = 10;
            data2.expiryTime = [NSDate dateWithTimeIntervalSince1970:1000.0];
            data2.tags = [NSSet setWithArray:@[@"TAG1", @"TAG2"]];
            data2.data = @{ @"CAT" : @"PRETTY" };
            data2.triggerType = PCFPushTriggerTypeEnterOrExit;
            data2.locations = @[ location2 ];

            [[theValue([data1.locations isEqualToArray:data2.locations]) should] beYes];
            [[theValue([location1 isEqual:location1]) should] beYes];
            [[theValue([location2 isEqual:location2]) should] beYes];
            [[theValue([location1 isEqual:location2]) should] beYes];
            [[theValue([location2 isEqual:location1]) should] beYes];

            [[data1 should] equal:data2];
            [[data2 should] equal:data1];

        });

    });
});

SPEC_END
