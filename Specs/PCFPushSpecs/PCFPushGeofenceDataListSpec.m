//
//  PCFPushGeofenceDataSpec.m
//  PCFPushSpecs
//
//  Created by DX181-XL on 2015-04-14.
//
//

#import "Kiwi.h"
#import "PCFPushGeofenceDataList.h"
#import "PCFPushGeofenceDataList+Loaders.h"

SPEC_BEGIN(PCFPushGeofenceDataListSpec)

describe(@"PCFPushGeofenceDataList", ^{
    
    __block PCFPushGeofenceDataList *model;

    beforeEach(^{
    });
    
    afterEach(^{
        model = nil;
    });
    
    it(@"should be initializable", ^{
        model = [[PCFPushGeofenceDataList alloc] init];
        [[model shouldNot] beNil];
    });

    context(@"deserialization", ^{

        it(@"should do nothing if given a null data object", ^{
            model = [PCFPushGeofenceDataList listFromData:nil];
            [[model should] beNil];
        });

        it(@"should return an empty object if given an empty data object", ^{
            model = [PCFPushGeofenceDataList listFromData:[NSData data]];
            [[model should] beEmpty];
        });
    });
});

SPEC_END
