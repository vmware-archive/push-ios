//
//  PCFPushGeofenceResponseDataSpec.m
//  PCFPushSpecs
//
//  Created by DX181-XL on 2015-04-14.
//
//

#import "Kiwi.h"
#import "PCFPushGeofenceResponseData.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushErrors.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushGeofenceData.h"

SPEC_BEGIN(PCFPushGeofenceResponseDataSpec)

describe(@"PCFPushGeofenceResponseData", ^{

    __block PCFPushGeofenceResponseData *model;
    __block PCFPushSpecsHelper *helper;

    beforeEach(^{
        helper = [[PCFPushSpecsHelper alloc] init];
        [helper setupParameters];
    });

    afterEach(^{
        model = nil;
    });

    it(@"should be initializable", ^{
        model = [[PCFPushGeofenceResponseData alloc] init];
        [[model shouldNot] beNil];
    });

    context(@"fields", ^{

        beforeEach(^{
            model = [[PCFPushGeofenceResponseData alloc] init];
        });

        it(@"should start as nil", ^{
            [[theValue(model.number) should] beZero];
            [[model.lastModified should] beNil];
            [[model.geofences should] beNil];
            [[model.deletedGeofenceIds should] beNil];
        });

    });

    context(@"deserialization", ^{

        it(@"should handle a nil input", ^{
            NSError *error;
            model = [PCFPushGeofenceResponseData pcf_fromJSONData:nil error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
            [[error.domain should] equal:PCFPushErrorDomain];
            [[theValue(error.code) should] equal:theValue(PCFPushBackEndDataUnparseable)];
        });

        it(@"should handle empty input", ^{
            NSError *error;
            model = [PCFPushGeofenceResponseData pcf_fromJSONData:[NSData data] error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
            [[error.domain should] equal:PCFPushErrorDomain];
            [[theValue(error.code) should] equal:theValue(PCFPushBackEndDataUnparseable)];
        });

        it(@"should handle bad JSON", ^{
            NSError *error;
            NSData *JSONData = [@"I AM NOT JSON" dataUsingEncoding:NSUTF8StringEncoding];
            model = [PCFPushGeofenceResponseData pcf_fromJSONData:JSONData error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
        });

        it(@"should construct a complete response object", ^{
            NSError *error;
            NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"geofence_response_data_complex" ofType:@"json"];
            NSData *data = [NSData dataWithContentsOfFile:filePath];

            [[data shouldNot] beNil];

            model = [PCFPushGeofenceResponseData pcf_fromJSONData:data error:&error];
            [[error should] beNil];

            [[theValue(model.number) should] equal:theValue(3)];
            [[model.lastModified should] equal:[NSDate dateWithTimeIntervalSince1970:1424309210.305]];
            [[model.geofences should] haveCountOf:3];
            [[theValue(((PCFPushGeofenceData*)(model.geofences[0])).id) should] equal:theValue(5)];
            [[theValue(((PCFPushGeofenceData*)(model.geofences[1])).id) should] equal:theValue(10)];
            [[theValue(((PCFPushGeofenceData*)(model.geofences[2])).id) should] equal:theValue(44)];
            [[model.deletedGeofenceIds should] haveCountOf:2];
            [[model.deletedGeofenceIds should] containObjectsInArray:@[@9, @13]];
        });

        it(@"should handle deserializing last modified values", ^{
            model = [PCFPushGeofenceResponseData pcf_fromDictionary:@{ @"last_modified" : @0 } ];
            [[model.lastModified should] equal:[NSDate dateWithTimeIntervalSince1970:0.0]];

            model = [PCFPushGeofenceResponseData pcf_fromDictionary:@{ @"last_modified" : @10 } ];
            [[model.lastModified should] equal:[NSDate dateWithTimeIntervalSince1970:0.010]];

            model = [PCFPushGeofenceResponseData pcf_fromDictionary:@{ @"last_modified" : @1000 } ];
            [[model.lastModified should] equal:[NSDate dateWithTimeIntervalSince1970:1.0]];

            model = [PCFPushGeofenceResponseData pcf_fromDictionary:@{ @"last_modified" : [NSNull null] } ];
            [[model.lastModified should] beNil];

            model = [PCFPushGeofenceResponseData pcf_fromDictionary:@{ } ];
            [[model.lastModified should] beNil];
        });

        it(@"should handle deserializing list of geofences", ^{
            model = [PCFPushGeofenceResponseData pcf_fromDictionary:@{ } ];
            [[model.geofences should] beNil];

            model = [PCFPushGeofenceResponseData pcf_fromDictionary:@{ @"geofenes":[NSNull null]} ];
            [[model.geofences should] beNil];

            model = [PCFPushGeofenceResponseData pcf_fromDictionary:@{ @"geofenes":@[] } ];
            [[model.geofences should] beNil];
        });
    });

    context(@"serialization", ^{

        __block NSDictionary *dict = nil;
        __block PCFPushGeofenceData *data1;
        __block PCFPushGeofenceData *data2;

        beforeEach(^{
            model = [[PCFPushGeofenceResponseData alloc] init];
        });

        afterEach(^{
            dict = nil;
        });

        context(@"populated object", ^{

            beforeEach(^{
                model.number = 2;
                model.lastModified = [NSDate dateWithTimeIntervalSince1970:100.0];
                model.deletedGeofenceIds = @[ @2, @17, @22 ];

                data1 = [[PCFPushGeofenceData alloc] init];
                data1.id = 77L;
                data2 = [[PCFPushGeofenceData alloc] init];
                data2.id = 99L;

                model.geofences = @[ data1, data2 ];
            });

            afterEach(^{
                [[dict shouldNot] beNil];
                [[dict[@"num"] should] equal:theValue(2L)];
                [[dict[@"last_modified"] should] equal:@100000];
                [[dict[@"deleted_geofence_ids"] should] haveCountOf:3];
                [[dict[@"deleted_geofence_ids"] should] containObjectsInArray:@[@2, @17, @22]];
                [[dict[@"geofences"] should] haveCountOf:2];
                [[dict[@"geofences"][0][@"id"] should] equal:@77L];
                [[dict[@"geofences"][1][@"id"] should] equal:@99L];
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
                [[dict[@"num"] should] beZero];
                [[dict[@"last_modified"] should] beNil];
                [[dict[@"geofences"] should] beNil];
                [[dict[@"delete_geofence_ids"] should] beNil];
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

            it(@"should serialize various last modified times", ^{
                model.lastModified = nil;
                dict = [model pcf_toFoundationType];
                [[dict[@"last_modified"] should] beNil];

                model.lastModified = (NSDate*)(id)[NSNull null];
                dict = [model pcf_toFoundationType];
                [[dict[@"last_modified"] should] beNil];

                model.lastModified = [NSDate dateWithTimeIntervalSince1970:0];
                dict = [model pcf_toFoundationType];
                [[dict[@"last_modified"] should] beZero];

                model.lastModified = [NSDate dateWithTimeIntervalSince1970:0.10];
                dict = [model pcf_toFoundationType];
                [[dict[@"last_modified"] should] equal:@100L];

                model.lastModified = [NSDate dateWithTimeIntervalSince1970:1000];
                dict = [model pcf_toFoundationType];
                [[dict[@"last_modified"] should] equal:@1000000L];
            });

            it(@"should serialize list of geofences", ^{
                model.geofences = nil;
                dict = [model pcf_toFoundationType];
                [[dict[@"geofences"] should] beNil];

                model.geofences = (NSArray*)(id)[NSNull null];
                dict = [model pcf_toFoundationType];
                [[dict[@"geofences"] should] beNil];

                model.geofences = @[];
                dict = [model pcf_toFoundationType];
                [[dict[@"geofences"] should] beNil];
            });

            it(@"should serialize various deleted geofence ids", ^{
                model.deletedGeofenceIds = nil;
                dict = [model pcf_toFoundationType];
                [[dict[@"delete_geofence_ids"] should] beNil];

                model.deletedGeofenceIds = (NSArray*)(id)[NSNull null];
                dict = [model pcf_toFoundationType];
                [[dict[@"delete_geofence_ids"] should] beNil];

                model.deletedGeofenceIds = @[];
                dict = [model pcf_toFoundationType];
                [[dict[@"delete_geofence_ids"] should] beNil];
            });

        });
    });
});

SPEC_END
