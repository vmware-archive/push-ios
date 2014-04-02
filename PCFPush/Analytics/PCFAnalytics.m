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
#import "PCFPushCoreDataManager.h"
#import "PCFPushPersistentStorage.h"
#import "NSURLConnection+PCFPushBackEndConnection.h"

static NSTimeInterval minSecondsBetweenSends = 15.0f;
static NSUInteger maxEventsCount = 1000;

@implementation PCFAnalytics

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterBackground)
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

+ (void)enterBackground
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

+ (void)pruneEvents
{
    NSManagedObjectContext *context = [[PCFPushCoreDataManager shared] managedObjectContext];
    [context performBlockAndWait:^{
        NSFetchRequest *eventsFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(PCFAnalyticEvent.class)];
        [eventsFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(eventTime)) ascending:YES]]];
        
        NSError *error;
        NSArray *events = [context executeFetchRequest:eventsFetchRequest error:&error];
        if (error) {
            PCFPushCriticalLog(@"Prune events request failed with error: %@ %@", error, error.userInfo);
            return;
        }
        
        if (events.count > maxEventsCount) {
            events = [events subarrayWithRange:NSMakeRange(0, events.count - maxEventsCount)];
            [[PCFPushCoreDataManager shared] deleteManagedObjects:events];
        }
    }];
}

+ (void)sendAnalytics
{
    static CGFloat lastSendTime;
    CGFloat interval = ([[NSDate date] timeIntervalSince1970] - lastSendTime);
    if (interval > minSecondsBetweenSends) {
        NSManagedObjectContext *context = [[PCFPushCoreDataManager shared] managedObjectContext];
        
        [context performBlock:^{
            NSFetchRequest *eventsFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(PCFAnalyticEvent.class)];
            [eventsFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(eventTime)) ascending:NO]]];
            
            NSError *error;
            NSUInteger eventsCount = [context countForFetchRequest:eventsFetchRequest error:&error];
            if (error) {
                PCFPushCriticalLog(@"Events count request failed with error: %@ %@", error, error.userInfo);
                return;
            }
            
            if (eventsCount > maxEventsCount) {
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
                [NSURLConnection pcf_syncAnalyicEvents:events
                                           forDeviceID:[PCFPushPersistentStorage backEndDeviceID]
                                               success:^(NSURLResponse *response, NSData *data) {
                                                   if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                                                       PCFPushLog(@"Events successfully synced.");
                                                       [[PCFPushCoreDataManager shared] deleteManagedObjects:events];
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

@end
