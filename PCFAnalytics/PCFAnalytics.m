//
//  PCFAnalytics.m
//  
//
//  Created by DX123-XL on 2014-04-01.
//
//

#import "PCFAnalytics.h"
#import "PCFPushDebug.h"
#import "PCFAnalyticEvent.h"
#import "PCFCoreDataManager.h"
#import "PCFPushPersistentStorage.h"
#import "PCFAnalyticsURLConnection.h"

static NSTimeInterval minSecondsBetweenSends = 60.0f;
static NSUInteger maxStoredEventCount = 1000;
static NSUInteger maxBatchSize = 100;
static NSTimeInterval lastSendTime;

@implementation PCFAnalytics

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

+ (NSUInteger)maxStoredEventCount
{
    return maxStoredEventCount;
}

+ (void)setMaxStoredEventCount:(NSUInteger)maxCount
{
    maxStoredEventCount = maxCount;
}

+ (NSUInteger)maxBatchSize
{
    return maxBatchSize;
}

+ (void)setMaxBatchSize:(NSUInteger)batchSize
{
    maxBatchSize = batchSize;
}

+ (NSTimeInterval)minSecondsBetweenSends
{
    return minSecondsBetweenSends;
}

+ (void)setMinSecondsBetweenSends:(NSTimeInterval)minSeconds
{
    minSecondsBetweenSends = minSeconds;
}

+ (NSTimeInterval)lastSendTime
{
    return lastSendTime;
}

+ (void)setLastSendTime:(NSTimeInterval)sendTime
{
    lastSendTime = sendTime;
}

#pragma mark - Notification selectors

+ (void)didEnterBackground
{
    PCFPushLog(@"Enter Background - Event Logged.");
    [PCFAnalyticEvent logEventBackground];
    [self sendAnalytics];
}

+ (void)didBecomeActive
{
    PCFPushLog(@"Did Become Active - Event Logged.");
    [PCFAnalyticEvent logEventAppActive];
}

+ (void)willResignActive
{
    PCFPushLog(@"Will Resign Active - Event Logged.");
    [PCFAnalyticEvent logEventAppInactive];
}

#pragma mark - Database maintenance

+ (void)pruneEvents
{
    NSManagedObjectContext *context = [[PCFCoreDataManager shared] managedObjectContext];
    [context performBlockAndWait:^{
        NSFetchRequest *eventsFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(PCFAnalyticEvent.class)];
        [eventsFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(eventTime)) ascending:YES]]];
        
        NSError *error;
        NSArray *events = [context executeFetchRequest:eventsFetchRequest error:&error];
        if (error) {
            PCFPushCriticalLog(@"Prune events request failed with error: %@ %@", error, error.userInfo);
            return;
        }
        
        if (events.count > maxStoredEventCount) {
            events = [events subarrayWithRange:NSMakeRange(0, events.count - maxStoredEventCount)];
            [[PCFCoreDataManager shared] deleteManagedObjects:events];
        }
    }];
}

#pragma mark - Analytics Request

+ (BOOL)shouldSendAnalytics
{
    CGFloat interval = ([[NSDate date] timeIntervalSince1970] - lastSendTime);
    return interval > minSecondsBetweenSends;
}

+ (NSArray *)batchRequestsFromEvents:(NSArray *)events
{
    NSMutableArray *requestBatches = [NSMutableArray array];
    
    if (events.count > maxBatchSize) {
        NSUInteger batchIndex = 0;
        
        while (batchIndex < events.count) {
            NSUInteger rangeLength = MIN(events.count - batchIndex, maxBatchSize);
            [requestBatches addObject:[events subarrayWithRange:NSMakeRange(batchIndex, rangeLength)]];
            batchIndex += rangeLength;
        }
        
    } else {
        [requestBatches addObject:events];
    }
    
    return [NSArray arrayWithArray:requestBatches];
}

+ (void)sendAnalytics
{
    if (![PCFPushPersistentStorage analyticsEnabled]) {
        PCFPushLog(@"Analytics disabled. Events will not be sent.");
        return;
    }
    
    if ([self shouldSendAnalytics]) {
        NSManagedObjectContext *context = [[PCFCoreDataManager shared] managedObjectContext];
        
        [context performBlock:^{
            NSFetchRequest *eventsFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(PCFAnalyticEvent.class)];
            [eventsFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(eventTime)) ascending:NO]]];
            
            NSError *error;
            NSUInteger eventsCount = [context countForFetchRequest:eventsFetchRequest error:&error];
            if (error) {
                PCFPushCriticalLog(@"Events count request failed with error: %@ %@", error, error.userInfo);
                return;
            }
            
            if (eventsCount > maxStoredEventCount) {
                [self pruneEvents];
            }
            
            NSArray *events = [context executeFetchRequest:eventsFetchRequest error:&error];
            if (error) {
                PCFPushCriticalLog(@"Events fetch request failed with error: %@ %@", error, error.userInfo);
                return;
            }
            
            PCFPushLog(@"Events fetched from Core Data.");
            
            if (events.count > 0) {
                lastSendTime = [[NSDate date] timeIntervalSince1970];
                NSArray *requestBatches = [self batchRequestsFromEvents:events];
                
                PCFPushLog(@"Sync Analytic Events Started");
                [requestBatches enumerateObjectsUsingBlock:^(NSArray *batchedEvents, NSUInteger idx, BOOL *stop) {
                    [PCFAnalyticsURLConnection syncAnalyicEvents:batchedEvents
                                                     forDeviceID:[PCFPushPersistentStorage pushServerDeviceID]
                                                         success:^(NSURLResponse *response, NSData *data) {
                                                             if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                                                                 PCFPushLog(@"Events successfully synced.");
                                                                 [[PCFCoreDataManager shared] deleteManagedObjects:batchedEvents];
                                                             } else {
                                                                 PCFPushLog(@"Events failed to sync.");
                                                             }
                                                         }
                                                         failure:^(NSError *error) {
                                                             PCFPushLog(@"Events failed to sync.");
                                                         }];
                }];
            }
        }];
    }
}

#pragma mark - Remote Notification Logging

+ (void)logApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self logApplication:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:nil];
}

+ (void)logApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSString *appState;
    switch (application.applicationState) {
        case UIApplicationStateActive:
            appState = @"UIApplicationStateActive";
            break;
        case UIApplicationStateInactive:
            appState = @"UIApplicationStateInactive";
            break;
        case UIApplicationStateBackground:
            appState = @"UIApplicationStateBackground";
            break;
        default:
            appState = @"unknown";
            break;
    }
    
    NSDictionary *pushReceivedData = [NSMutableDictionary dictionaryWithCapacity:2];
    [pushReceivedData setValue:appState forKey:PushNotificationKeys.appState];
    
    id pushID = [userInfo objectForKey:PushNotificationKeys.pushID];
    if (pushID) {
        [pushReceivedData setValue:pushID forKey:PushNotificationKeys.pushID];
    }
    [PCFAnalyticEvent logEventPushReceivedWithData:pushReceivedData];
}

@end
