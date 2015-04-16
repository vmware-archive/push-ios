//
// Created by DX181-XL on 15-04-15.
//

#import "Kiwi.h"
#import "PCFPushGeofenceEngine.h"
#import "PCFPushSpecsHelper.h"


SPEC_BEGIN(PCFPushGeofenceEngineSpec)

    describe(@"PCFPushGeofenceEngine", ^{

        __block PCFPushGeofenceEngine *model;
        __block PCFPushSpecsHelper *helper;

        beforeEach(^{
            helper = [[PCFPushSpecsHelper alloc] init];
            [helper setupParameters];
        });

        afterEach(^{
            model = nil;
        });

    });

SPEC_END