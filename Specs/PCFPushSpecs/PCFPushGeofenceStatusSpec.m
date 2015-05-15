//
// Created by DX181-XL on 15-04-15.
//

#import "Kiwi.h"
#import "PCFPushGeofenceStatus.h"
#import "PCFPushGeofenceStatusUtil.h"
#import "PCFPushGeofenceDataList+Loaders.h"

SPEC_BEGIN(PCFPushGeofenceStatusSpec)

    describe(@"PCFPushGeofenceStatus", ^{

        __block PCFPushGeofenceStatus *status;

        it(@"should let you create status objects with nil error reasons", ^{
            status = [PCFPushGeofenceStatus statusWithError:NO errorReason:nil number:0];
            [[theValue(status.isError) should] beNo];
            [[theValue(status.numberOfCurrentlyMonitoredGeofences) should] beZero];
            [[status.errorReason should] beNil];
        });

        it(@"should let you create status objects with NSNull error reasons", ^{
            id errorReason = [NSNull null];
            status = [PCFPushGeofenceStatus statusWithError:NO errorReason:errorReason number:0];
            [[theValue(status.isError) should] beNo];
            [[theValue(status.numberOfCurrentlyMonitoredGeofences) should] beZero];
            [[status.errorReason should] beNil];
        });

        it(@"should let you create status objects with actual values", ^{
            status = [PCFPushGeofenceStatus statusWithError:YES errorReason:@"ERROR" number:57];
            [[theValue(status.isError) should] beYes];
            [[theValue(status.numberOfCurrentlyMonitoredGeofences) should] equal:theValue(57)];
            [[status.errorReason should] equal:@"ERROR"];
        });
    });

SPEC_END