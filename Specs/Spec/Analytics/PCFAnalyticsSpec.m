//
//  PCFAnalyticsSpec.m
//  PCFPushSpec
//
//  Created by DX123-XL on 2014-04-02.
//
//

#import "Kiwi.h"

SPEC_BEGIN(PCFAnalyticsSpec)

describe(@"PCFAnalytics", ^{
    
    context(@"UIApplicationNotifications", ^{
        beforeEach(^{
            //Setup persistent store to mimic registration complete
        });
        
        it(@"should add event to analytics DB when application becomes active.", ^{
            fail(@"incomplete");
        });
        
        it(@"should add event to analytics DB when application resigns active.", ^{
            fail(@"incomplete");
        });
        
        it(@"should add event to analytics DB when application enters background.", ^{
            fail(@"incomplete");
        });
        
        it(@"should send events in analytics DB to remote server when application enters background.", ^{
            fail(@"incomplete");
        });
    });
    
    context(@"Maximum message body size.", ^{
        
        beforeEach(^{
            //Load database with more than the maximum number of events.
        });
        
        it(@"should not send a POST with more than the maxiumum number of events.", ^{
            fail(@"incomplete");
        });
        
        it(@"should not store more than the maximum number of events in the DB", ^{
            fail(@"incomplete");
        });
    });
    
    context(@"Receive push notificiation without a push ID.", ^{
        it(@"should record an event when the application receives a remote push notification", ^{
            fail(@"incomplete");
        });

        it(@"recorded event should be of type push received.", ^{
            fail(@"incomplete");
        });
        
        it(@"recorded event should have a time stamp close to the current time.", ^{
            fail(@"incomplete");
        });
        
        it(@"recorded event should have a data parameter with the application state.", ^{
            fail(@"incomplete");
        });
        
        it(@"recorded event should not have a push ID if not included in the push message.", ^{
            fail(@"incomplete");
        });
    });

    context(@"Receive push notificiation with a push ID.", ^{
        
        it(@"should record an event when the application receives a remote push notification.", ^{
            fail(@"incomplete");
        });
        
        it(@"recorded event should have a push ID if included in the push message.", ^{
            fail(@"incomplete");
        });
    });
    
    context(@"Batch sending of analytic events.", ^{
        it(@"should not send analytic events more requently than the min interval.", ^{
            fail(@"incomplete");
        });
    });
});

SPEC_END