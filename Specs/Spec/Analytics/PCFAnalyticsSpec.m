//
//  PCFAnalyticsSpec.m
//  PCFPushSpec
//
//  Created by DX123-XL on 2014-04-02.
//
//

#import "Kiwi.h"
#import <objc/runtime.h>

#import "PCFPushURLConnection.h"
#import "PCFPushSpecHelper.h"
#import "PCFPushBackEndRegistrationDataTest.h"
#import "PCFPushBackEndRegistrationResponseDataTest.h"
#import "PCFAppDelegateProxy.h"
#import "PCFPushClient.h"
#import "PCFPushSDK.h"
#import "PCFSDK+Analytics.h"
#import "PCFAnalytics_TestingHeader.h"
#import "PCFAnalyticEvent_TestingHeader.h"
#import "PCFCoreDataManager.h"
#import "NSURLConnection+PCFBackEndConnection.h"
#import "PCFPushAppDelegate+Analytics.h"

SPEC_BEGIN(PCFAnalyticsSpec)

describe(@"PCFAnalytics", ^{
    
    __block PCFPushSpecHelper *helper;
    __block PCFCoreDataManager *manager;
    
    beforeEach(^{
        helper = [[PCFPushSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupApplicationForSuccessfulRegistration];
        [helper setupDefaultSavedParameters];
        [helper setupParameters];
        
        manager = [PCFCoreDataManager shared];
        [[manager managedObjectContext] stub:@selector(performBlock:) withBlock:^id(NSArray *params) {
            void (^block)() = params[0];
            [[manager managedObjectContext] performBlockAndWait:block];
            return nil;
        }];
        
        [manager deleteManagedObjects:[manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])]];
    });
    
    context(@"UIApplicationNotifications", ^{
        
        __block NSString *entityName;
        __block NSString *expectedEventType;
        __block NSInteger expectedCountOFEvents = -1;
        
        beforeEach(^{
            [PCFSDK setAnalyticsEnabled:YES];
            [PCFSDK setRegistrationParameters:helper.params];
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                NSError *error;
                NSDictionary *eventsDictionary = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:NSJSONReadingAllowFragments error:&error];
                if (error) {
                    fail(@"HTTP body data is not valid JSON.");
                }
                
                [[eventsDictionary should] beKindOfClass:[NSDictionary class]];
                [[[eventsDictionary allKeys] should] containObjectsInArray:@[@"events", @"device_id"]];
                
                [[theValue([(NSArray *)eventsDictionary[@"events"] count]) should] equal:theValue(1)];
                NSDictionary *event = eventsDictionary[@"events"][0];
                NSString *backgroundString =  EventTypes.backgrounded;
                [[[event objectForKey:EventRemoteAttributes.eventType] should] equal:backgroundString];
                
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];
            
            [PCFAnalytics stub:@selector(shouldSendAnalytics) andReturn:theValue(YES)];
            
            entityName = NSStringFromClass([PCFAnalyticEvent class]);
            expectedEventType = nil;
            expectedCountOFEvents = -1;
        });
        
        afterEach(^{
            NSArray *events = [[PCFCoreDataManager shared] managedObjectsWithEntityName:entityName];
            
            [[theValue(events.count) should] equal:theValue(expectedCountOFEvents)];
            PCFAnalyticEvent *event = [events lastObject];
            
            if (event) {
                [[event should] beKindOfClass:NSClassFromString(entityName)];
                [[event.eventType should] equal:expectedEventType];
            }
        });
        
        it(@"should add event to analytics DB when application becomes active.", ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil userInfo:nil];
            expectedEventType = EventTypes.active;
            expectedCountOFEvents = 1;
        });
        
        it(@"should add event to analytics DB when application resigns active.", ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:nil userInfo:nil];
            expectedEventType = EventTypes.inactive;
            expectedCountOFEvents = 1;
        });
        
        it(@"should add event to analytics DB and send to remote server when application enters background.", ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
            expectedEventType = EventTypes.backgrounded;
            expectedCountOFEvents = 0;
        });
    });
    
    context(@"Maximum message body size.", ^{
        __block NSInteger maxEventCount = 0;
        beforeEach(^{
            [PCFSDK setAnalyticsEnabled:YES];
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                NSError *error;
                NSArray *events = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:NSJSONReadingAllowFragments error:&error];
                if (error) {
                    fail(@"HTTP body data is not valid JSON.");
                }
                [[theValue(events.count) should] beLessThanOrEqualTo:theValue([PCFAnalytics maxBatchSize])];
                maxEventCount += events.count;
                
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];
            
            [PCFAnalytics stub:@selector(shouldSendAnalytics) andReturn:theValue(YES)];
            
            NSManagedObjectContext *context = [[PCFCoreDataManager shared] managedObjectContext];
            [context performBlockAndWait:^{
                NSUInteger maxCount = [PCFAnalytics maxStoredEventCount];
                for (int i = 0; i < maxCount + 1; i++) {
                    [PCFAnalytics insertIntoContext:context eventWithType:EventTypes.foregrounded data:@{@"event_count" : @(i)}];
                }

                NSError *error;
                if (![context save:&error]) {
                    fail(@"Loading DB with events failed. %@ %@", error, error.userInfo);
                }
            }];
            
            maxEventCount = 0;
        });
        
        it(@"should not send a POST with more than the maxiumum batch size of events.", ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
        });
        
        it(@"should prune events past the maximum number of events in the DB.", ^{
            NSArray *events = [manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
            [[theValue(events.count) should] beGreaterThan:theValue([PCFAnalytics maxStoredEventCount])];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
            
            [[theValue(maxEventCount) should] beLessThanOrEqualTo:theValue([PCFAnalytics maxStoredEventCount])];
        });
        
#warning - Implement gzip HTTPbody.
        
//        it(@"the POST request body should be zipped", ^{
//            fail(@"incomplete");
//        });
    });
    
    context(@"Receive push notificiation without a push ID.", ^{
        beforeEach(^{
            [PCFSDK setAnalyticsEnabled:YES];
            
            [PCFSDK load];
            [PCFSDK setRegistrationParameters:helper.params];
            
            [helper.application stub:@selector(applicationState) andReturn:theValue(UIApplicationStateActive)];
            [helper.applicationDelegate application:helper.application didReceiveRemoteNotification:@{}];
        });
        
        it(@"should record an event when the application receives a remote push notification", ^{
            NSArray *events = [manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
            [[theValue(events.count) should] equal:theValue(1)];
        });

        it(@"recorded event should be of type push received.", ^{
            NSArray *events = [manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
            PCFAnalyticEvent *event = [events lastObject];
            [[event should] beKindOfClass:[PCFAnalyticEvent class]];
            [[event.eventType should] equal:PushNotificationEvents.pushReceived];
        });
        
        it(@"recorded event should have a time stamp close to the current time.", ^{
            NSArray *events = [manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
            PCFAnalyticEvent *event = [events lastObject];
            
            NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            NSNumber *eventTime = [formatter numberFromString:event.eventTime];
            [[theValue(eventTime.doubleValue - time) should] beBetween:theValue(-10.0f) and:theValue(10.0f)];
        });
        
        it(@"recorded event should have a data parameter with the application state.", ^{
            NSArray *events = [manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
            PCFAnalyticEvent *event = [events lastObject];
            [[[event.eventData objectForKey:PushNotificationKeys.appState] shouldNot] beNil];
        });
        
        it(@"recorded event should not have a push ID if not included in the push message.", ^{
            NSArray *events = [manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
            PCFAnalyticEvent *event = [events lastObject];
            [[[event.eventData objectForKey:PushNotificationKeys.pushID] should] beNil];
        });
    });

    context(@"Receive push notificiation with a push ID.", ^{
        __block NSArray *events;
        
        beforeEach(^{
            [PCFSDK setAnalyticsEnabled:YES];
            
            [helper.application stub:@selector(applicationState) andReturn:theValue(UIApplicationStateActive)];
            [helper.applicationDelegate application:helper.application didReceiveRemoteNotification:@{PushNotificationKeys.pushID : @"PUSH_ID"}];
            events = [manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
        });
        
        it(@"should record an event when the application receives a remote push notification.", ^{
            [[theValue(events.count) should] equal:theValue(1)];
        });
        
        it(@"recorded event should have a push ID if included in the push message.", ^{
            PCFAnalyticEvent *event = [events lastObject];
            [[[event.eventData objectForKey:PushNotificationKeys.pushID] shouldNot] beNil];
        });
    });
    
    context(@"Batch sending of analytic events.", ^{
        
        beforeEach(^{
            [PCFSDK setAnalyticsEnabled:YES];
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                NSError *error;
                [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:NSJSONReadingAllowFragments error:&error];
                if (error) {
                    fail(@"HTTP body data is not valid JSON.");
                }
                
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];
            
            [PCFAnalytics setLastSendTime:[[NSDate date] timeIntervalSince1970] - [PCFAnalytics minSecondsBetweenSends]];
        });

        it(@"should not send analytic events more requently than the min interval.", ^{
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:) withCount:1];
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
        });
        
        it(@"events DB table should be empty after sync completes.", ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
            NSArray *events = [[PCFCoreDataManager shared] managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
            [[theValue(events.count) should] beZero];
        });
    });
    
    context(@"Batch send fails of analytic events.", ^{
        beforeEach(^{
            [PCFSDK setAnalyticsEnabled:YES];
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                NSError *error;
                [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:NSJSONReadingAllowFragments error:&error];
                if (error) {
                    fail(@"HTTP body data is not valid JSON.");
                }
                
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:404 HTTPVersion:nil headerFields:nil];
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];
            
            [PCFAnalytics setLastSendTime:[[NSDate date] timeIntervalSince1970] - [PCFAnalytics minSecondsBetweenSends]];
        });
        
        it(@"should not delete events from the database if request fails.", ^{
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:) withCount:1];
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
            NSArray *events = [[PCFCoreDataManager shared] managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
            [[theValue(events.count) should] beGreaterThanOrEqualTo:theValue(1)];
        });
    });
});

describe(@"PCFAnalytics + PCFPush", ^{
    __block PCFPushSpecHelper *helper;
    
    void(^forceLoadSDK)() = ^{
        [PCFPushSDK load];
        [PCFPushSDK setRegistrationParameters:helper.params];
        [[[helper.applicationDelegate class] should] equal:[PCFAppDelegateProxy class]];
    };
    
    beforeEach(^{
        helper = [[PCFPushSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupParameters];
        [helper.application stub:@selector(applicationState) andReturn:theValue(UIApplicationStateActive)];
        
        [PCFPushClient resetSharedClient];
        [helper setupApplicationForSuccessfulRegistration];
        [helper setupApplicationDelegateForSuccessfulRegistration];
        
    });
    
    afterEach(^{
        [helper reset];
    });
    
    context(@"BackgroundFetchResult processing with multiple appDelegates", ^{
        __block NSInteger totalExecutionCount = -1;
        
        void(^sendFakeRemotePush)() = ^{
            [helper.applicationDelegate application:helper.application
                       didReceiveRemoteNotification:@{@"alert" : @"Analytics Test"}
                             fetchCompletionHandler:^(UIBackgroundFetchResult result) {
                                 totalExecutionCount++;
                             }];
        };
        
        beforeEach(^{
            totalExecutionCount = 0;
        });
        
        afterEach(^{
            [[theValue(totalExecutionCount) should] equal:theValue(1)];
        });
        
        it(@"should call 'application:didReceiveRemoteNotification:fetchCompletionHandler:' only on swapped AppDelegate if original AppDelegate does not implement the method.", ^{
            [helper setupMockApplicationDelegateWithoutRemotePush];
            
            forceLoadSDK();
            
            [[[(PCFAppDelegateProxy *)helper.applicationDelegate swappedAppDelegate] should] beKindOfClass:[PCFAppDelegate class]];
            [[[(PCFAppDelegateProxy *)helper.applicationDelegate originalAppDelegate] shouldNot] receive:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
            
            sendFakeRemotePush();
        });
        
        it(@"should call 'application:didReceiveRemoteNotification:fetchCompletionHandler:' on both original and swapped AppDelegate", ^{
            [helper setupMockApplicationDelegateWithRemotePush];
            
            forceLoadSDK();
            
            [[[(PCFAppDelegateProxy *)helper.applicationDelegate swappedAppDelegate] should] beKindOfClass:[PCFAppDelegate class]];
            [[[(PCFAppDelegateProxy *)helper.applicationDelegate originalAppDelegate] should] receive:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
            
            sendFakeRemotePush();
        });
    });
});

context(@"Tracking analytic events when push events occur", ^{
    __block PCFCoreDataManager *manager;
    __block PCFPushSpecHelper *helper;
    
    void(^stubURLConnection)() = ^{
        [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
            NSURLRequest *request = params[0];
            NSString *authValue = request.allHTTPHeaderFields[kBasicAuthorizationKey];
            [[authValue shouldNot] beNil];
            [[authValue should] startWithString:@"Basic "];
            [[authValue should] endWithString:helper.base64AuthString1];
            
            __block NSHTTPURLResponse *newResponse;
            __block NSData *newData;
            
            if ([request.HTTPMethod isEqualToString:@"PUT"] || [request.HTTPMethod isEqualToString:@"POST"]) {
                newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                NSDictionary *dict = @{
                                       RegistrationAttributes.deviceOS           : TEST_OS,
                                       RegistrationAttributes.deviceOSVersion    : TEST_OS_VERSION,
                                       RegistrationAttributes.deviceAlias        : TEST_DEVICE_ALIAS,
                                       RegistrationAttributes.deviceManufacturer : TEST_DEVICE_MANUFACTURER,
                                       RegistrationAttributes.deviceModel        : TEST_DEVICE_MODEL,
                                       RegistrationAttributes.variantUUID        : TEST_VARIANT_UUID,
                                       RegistrationAttributes.registrationToken  : TEST_REGISTRATION_TOKEN,
                                       kDeviceUUID                               : TEST_DEVICE_UUID,
                                       };
                newData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
                
            } else if ([request.HTTPMethod isEqualToString:@"DELETE"]) {
                newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:204 HTTPVersion:nil headerFields:nil];
            }

            
            CompletionHandler handler = params[2];
            handler(newResponse, newData, nil);
            return nil;
        }];
    };
    
    BOOL(^containsEventType)(NSArray *, NSString *) = ^BOOL(NSArray *events, NSString *eventType) {
        __block BOOL containsEvent = NO;
        [events enumerateObjectsUsingBlock:^(PCFAnalyticEvent *analyticEvent, NSUInteger idx, BOOL *stop) {
            if([analyticEvent.eventType isEqualToString:eventType]) {
                containsEvent = YES;
                *stop = YES;
            }
        }];
        return containsEvent;
    };
    
    beforeEach(^{
        [[PCFCoreDataManager shared] flushDatabase];
        NSArray *events = [manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
        [[theValue(events.count) should] beZero];
        
        [PCFCoreDataManager setSharedManager:nil];
        
        manager = [PCFCoreDataManager shared];
        [[manager managedObjectContext] stub:@selector(performBlock:) withBlock:^id(NSArray *params) {
            void (^block)() = params[0];
            [[manager managedObjectContext] performBlockAndWait:block];
            return nil;
        }];
        
        helper = [[PCFPushSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupParameters];
        
        stubURLConnection();
    });
    
    it(@"should add a registration successful event to the events database when push registration is successful", ^{
        NSArray *events = [manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
        [[theValue(containsEventType(events, EventTypes.registered)) should] beFalse];
        
        [[PCFPushClient shared] APNSRegistrationSuccess:helper.apnsDeviceToken];
        
        events = [manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
        [[theValue(containsEventType(events, EventTypes.registered)) should] beTrue];
    });
    
    it(@"should add a unregistration successful event to the events database when push unregistration is successful", ^{
        [helper setupDefaultSavedParameters];
        
        NSArray *events = [manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
        [[theValue(containsEventType(events, EventTypes.unregistered)) should] beFalse];
        
        [PCFPushSDK unregisterWithPushServerSuccess:^{
        } failure:^(NSError *error) {
            fail(@"Unregistration call should not have failed.");
        }];
        
        events = [manager managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
        [[theValue(containsEventType(events, EventTypes.unregistered)) should] beTrue];
    });
});

SPEC_END