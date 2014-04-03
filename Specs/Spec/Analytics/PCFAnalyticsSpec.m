//
//  PCFAnalyticsSpec.m
//  PCFPushSpec
//
//  Created by DX123-XL on 2014-04-02.
//
//

#import "Kiwi.h"

#import "PCFPushSpecHelper.h"
#import "PCFPushSDK.h"
#import "PCFAnalytics_TestingHeader.h"
#import "PCFAnalyticEvent.h"
#import "PCFCoreDataManager.h"

SPEC_BEGIN(PCFAnalyticsSpec)

describe(@"PCFAnalytics", ^{
    
    __block PCFPushSpecHelper *helper;
    __block UIRemoteNotificationType testNotificationTypes = TEST_NOTIFICATION_TYPES;
    
    beforeEach(^{
        helper = [[PCFPushSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
        [helper setupDefaultSavedParameters];
        
        [[[PCFCoreDataManager shared] managedObjectContext] stub:@selector(performBlock:) withBlock:^id(NSArray *params) {
            void (^block)() = params[0];
            [[[PCFCoreDataManager shared] managedObjectContext] performBlockAndWait:block];
            return nil;
        }];
    });
    
    context(@"UIApplicationNotifications", ^{
        
        __block NSString *entityName;
        __block NSString *eventType;
        __block NSInteger expectedCountOFEvents = -1;
        
        beforeEach(^{
            PCFCoreDataManager *manager = [PCFCoreDataManager shared];
            
            typedef void (^Handler)(NSURLResponse *response, NSData *data, NSError *connectionError);
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                NSError *error;
                NSArray *events = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:NSJSONReadingAllowFragments error:&error];
                if (error) {
                    fail(@"HTTP body data is not valid JSON.");
                }
                [[theValue(events.count) should] equal:theValue(1)];
                NSDictionary *event = events[0];
                [[[event objectForKey:EventRemoteAttributes.eventType] should] equal:EventTypes.backgrounded];
                
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                Handler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];
            
            [PCFAnalytics stub:@selector(shouldSendAnalytics) andReturn:theValue(YES)];
            
            [manager deleteManagedObjects:[manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])]];
            entityName = nil;
            eventType = nil;
            expectedCountOFEvents = -1;
        });
        
        afterEach(^{
            NSArray *events = [[PCFCoreDataManager shared] managedObjectsWithEntityName:entityName];
            
            [[theValue(events.count) should] equal:theValue(expectedCountOFEvents)];
            PCFAnalyticEvent *event = [events lastObject];
            [[event should] beKindOfClass:NSClassFromString(entityName)];
            [[event.eventType should] equal:eventType];
        });
        
        it(@"should add event to analytics DB when application becomes active.", ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil userInfo:nil];
            entityName = NSStringFromClass([PCFAnalyticEvent class]);
            eventType = EventTypes.active;
            expectedCountOFEvents = 1;
        });
        
        it(@"should add event to analytics DB when application resigns active.", ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:nil userInfo:nil];
            entityName = NSStringFromClass([PCFAnalyticEvent class]);
            eventType = EventTypes.inactive;
            expectedCountOFEvents = 1;
        });
        
        it(@"should add event to analytics DB and send to remote server when application enters background.", ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
            entityName = NSStringFromClass([PCFAnalyticEvent class]);
            eventType = EventTypes.backgrounded;
            expectedCountOFEvents = 0;
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
        
        it(@"events DB table should be empty after sync completes.", ^{
            fail(@"incomplete");
        });
    });
});

SPEC_END