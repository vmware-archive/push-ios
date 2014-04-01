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

+ (void)sendAnalytics
{
    static CGFloat lastSendDate;
    
    CGFloat interval = ([[NSDate date] timeIntervalSince1970] - lastSendDate);
    if (interval > minSecondsBetweenSends) {
        NSManagedObjectContext *context = [[PCFPushCoreDataManager shared] managedObjectContext];
        
        [context performBlock:^{
            NSFetchRequest *eventsFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(PCFAnalyticEvent.class)];
            [eventsFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(eventTime)) ascending:NO]]];
            
            NSError *error;
            NSArray *events = [context executeFetchRequest:eventsFetchRequest error:&error];
            PCFPushLog(@"Events fetched from Core Data.");
            
            if (events.count > 0) {
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
