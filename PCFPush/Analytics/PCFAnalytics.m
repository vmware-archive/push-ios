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
#import "NSURLConnection+PCFPushBackEndConnection.h"

static NSTimeInterval minSecondsBetweenSends = 60.0f;
static NSUInteger maxStoredEventCount = 1000;
static CGFloat lastSendTime;

static NSString *const kAppStateKey = @"app_state";
static NSString *const kPushIDKey = @"push_id";

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
                
                PCFPushLog(@"Sync Analytic Events Started");
                [NSURLConnection pcf_syncAnalyicEvents:events
                                           forDeviceID:[PCFPushPersistentStorage backEndDeviceID]
                                               success:^(NSURLResponse *response, NSData *data) {
                                                   if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                                                       PCFPushLog(@"Events successfully synced.");
                                                       [[PCFCoreDataManager shared] deleteManagedObjects:events];
                                                   } else {
                                                       PCFPushLog(@"Events failed to sync.");
                                                   }
                                               }
                                               failure:^(NSError *error) {
                                                   PCFPushLog(@"Events failed to sync.");
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
    [pushReceivedData setValue:appState forKey:kAppStateKey];
    
    id pushID = [userInfo objectForKey:kPushIDKey];
    if (pushID) {
        [pushReceivedData setValue:pushID forKey:kPushIDKey];
    }
    [PCFAnalyticEvent logEventPushReceivedWithData:pushReceivedData];
}

@end
