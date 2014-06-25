//
//  PMSSAnalytics.m
//  
//
//  Created by DX123-XL on 2014-04-01.
//
//

#import <UIKit/UIKit.h>

#import "PMSSAnalytics.h"
#import "PMSSPushDebug.h"
#import "PMSSAnalyticEvent.h"
#import "PMSSCoreDataManager.h"
#import "PMSSPersistentStorage+Analytics.h"
#import "PMSSAnalyticsURLConnection.h"
#import "PMSSHardwareUtil.h"
#import "PMSSNotifications.h"

#define PMSS_ADD_OBSERVER(observer_selector, notification_name) [[NSNotificationCenter defaultCenter] addObserver:self selector:observer_selector name:notification_name object:nil];

static NSTimeInterval minSecondsBetweenSends = 60.0f;
static NSUInteger maxStoredEventCount = 1000;
static NSUInteger maxBatchSize = 100;
static NSTimeInterval lastSendTime;


const struct EventTypes {
    PMSS_STRUCT_STRING *error;
    PMSS_STRUCT_STRING *active;
    PMSS_STRUCT_STRING *inactive;
    PMSS_STRUCT_STRING *backgrounded;
    PMSS_STRUCT_STRING *foregrounded;
    PMSS_STRUCT_STRING *registered;
    PMSS_STRUCT_STRING *unregistered;
} EventTypes;

const struct EventTypes EventTypes = {
    .error        = @"event_error",
    .active       = @"event_app_active",
    .inactive     = @"event_app_inactive",
    .backgrounded = @"event_backgrounded",
    .foregrounded = @"event_foregrounded",
    .registered   = @"event_push_registered",
    .unregistered = @"event_push_unregistered",
};


static const struct ErrorEventKeys {
    PMSS_STRUCT_STRING *errorID;
    PMSS_STRUCT_STRING *errorMessage;
} ErrorEventKeys;

static const struct ErrorEventKeys ErrorEventKeys = {
    .errorID        = @"id",
    .errorMessage   = @"message",
};


static const struct ErrorType {
    PMSS_STRUCT_STRING *exception;
    PMSS_STRUCT_STRING *error;
} ErrorType;

static const struct ErrorType ErrorType = {
    .exception = @"exception",
    .error          = @"error",
};

@implementation PMSSAnalytics

+ (void)load
{
    PMSS_ADD_OBSERVER(@selector(didEnterBackground), UIApplicationDidEnterBackgroundNotification);
    PMSS_ADD_OBSERVER(@selector(willEnterForground), UIApplicationWillEnterForegroundNotification);
    PMSS_ADD_OBSERVER(@selector(didBecomeActive), UIApplicationDidBecomeActiveNotification);
    PMSS_ADD_OBSERVER(@selector(willResignActive), UIApplicationWillResignActiveNotification);
    PMSS_ADD_OBSERVER(@selector(registrationSuccessful), PMSSPushRegistrationSuccessNotification);
    PMSS_ADD_OBSERVER(@selector(unregisterSuccessful), PMSSPushUnregisterNotification);
}

#pragma mark - static propery getters/setters

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
    PMSSPushLog(@"Enter Background - Logging event.");
    [self logEvent:EventTypes.backgrounded];
    [self sendAnalytics];
}

+ (void)willEnterForground
{
    PMSSPushLog(@"Will Enter Foreground - Logging event.");
    [self logEvent:EventTypes.foregrounded];
}

+ (void)didBecomeActive
{
    PMSSPushLog(@"Did Become Active - Logging event.");
    static NSDictionary *params;
    if (!params) {
        NSString *shortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        params = @{
                   @"application_version" : shortVersion?:@"NA",
                   @"os" : [PMSSHardwareUtil operatingSystem],
                   @"os_version" : [PMSSHardwareUtil operatingSystemVersion],
                   @"device_manufacturer" : [PMSSHardwareUtil deviceManufacturer],
                   @"device_model" : [PMSSHardwareUtil deviceModel],
                   };
    }
    [self logEvent:EventTypes.active withParameters:params];
}

+ (void)willResignActive
{
    PMSSPushLog(@"Will Resign Active - Logging event.");
    [self logEvent:EventTypes.inactive];
}

+ (void)registrationSuccessful
{
    PMSSPushLog(@"Push Registration Successful - Logging event.");
    [self logEvent:EventTypes.registered];
}

+ (void)unregisterSuccessful
{
    PMSSPushLog(@"Push Unregistration Successful - Logging event.");
    [self logEvent:EventTypes.unregistered];
}

#pragma mark - Event Database Logging

+ (void)logEvent:(NSString *)eventName
{
    [self logEvent:eventName withParameters:nil];
}

+ (void)logError:(NSString *)errorID message:(NSString *)message exception:(NSException *)exception
{
    NSDictionary *exceptionDict;
    
    if (exception) {
        exceptionDict = @{
                          @"name" : exception.name,
                          @"reason" : exception.reason,
                          @"userInfo" : exception.userInfo,
                          };
    }
    [self logError:EventTypes.error message:message parameters:exceptionDict errorType:ErrorType.exception];
}

+ (void)logError:(NSString *)errorID message:(NSString *)message error:(NSError *)error
{
    NSDictionary *errorDict;
    
    if (error) {
        errorDict = @{
                      @"domain" : error.domain,
                      @"code" : @(error.code),
                      @"localizedDescription" : error.localizedDescription,
                      @"userInfo" : error.userInfo,
                      };
    }
    [self logError:EventTypes.error message:message parameters:errorDict errorType:ErrorType.error];
}

+ (void)logError:(NSString *)errorID message:(NSString *)message parameters:(NSDictionary *)parameters errorType:(NSString *)type
{
    NSMutableDictionary *errorParams = [NSMutableDictionary dictionaryWithCapacity:3];
    if (errorID) {
        [errorParams setObject:errorID forKey:ErrorEventKeys.errorID];
    }
    if (message) {
        [errorParams setObject:message forKey:ErrorEventKeys.errorMessage];
    }
    if (parameters) {
        [errorParams setObject:parameters forKey:type];
    }
    [self logEvent:EventTypes.error withParameters:[NSDictionary dictionaryWithDictionary:errorParams]];
}

+ (void)logEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters
{
    if (![PMSSPersistentStorage analyticsEnabled]) {
        PMSSPushLog(@"Analytics disabled. Event will not be logged.");
        return;
    }
    
    NSManagedObjectContext *context = [[PMSSCoreDataManager shared] managedObjectContext];
    [context performBlock:^{
        [self insertIntoContext:context eventWithType:eventName data:parameters];
        NSError *error;
        if (![context save:&error]) {
            PMSSPushCriticalLog(@"Managed Object Context failed to save: %@ %@", error, error.userInfo);
        }
    }];
}

+ (void)insertIntoContext:(NSManagedObjectContext *)context
            eventWithType:(NSString *)eventType
                     data:(NSDictionary *)eventData
{
    NSEntityDescription *description = [NSEntityDescription entityForName:NSStringFromClass(PMSSAnalyticEvent.class) inManagedObjectContext:context];
    PMSSAnalyticEvent *event = [[PMSSAnalyticEvent alloc] initWithEntity:description insertIntoManagedObjectContext:context];
    [event setEventID:[[NSUUID UUID] UUIDString]];
    [event setEventType:eventType];
    [event setEventTime:[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]]];
    
    if (eventData) {
        [event setEventData:eventData];
    }
}

#pragma mark - Database maintenance

+ (void)pruneEvents
{
    NSManagedObjectContext *context = [[PMSSCoreDataManager shared] managedObjectContext];
    [context performBlockAndWait:^{
        NSFetchRequest *eventsFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(PMSSAnalyticEvent.class)];
        [eventsFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(eventTime)) ascending:YES]]];
        
        NSError *error;
        NSArray *events = [context executeFetchRequest:eventsFetchRequest error:&error];
        if (error) {
            PMSSPushCriticalLog(@"Prune events request failed with error: %@ %@", error, error.userInfo);
            return;
        }
        
        if (events.count > maxStoredEventCount) {
            events = [events subarrayWithRange:NSMakeRange(0, events.count - maxStoredEventCount)];
            [[PMSSCoreDataManager shared] deleteManagedObjects:events];
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
    if (![PMSSPersistentStorage analyticsEnabled]) {
        PMSSPushLog(@"Analytics disabled. Events will not be sent.");
        return;
    }
    
    if ([self shouldSendAnalytics]) {
        NSManagedObjectContext *context = [[PMSSCoreDataManager shared] managedObjectContext];
        
        [context performBlock:^{
            NSFetchRequest *eventsFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(PMSSAnalyticEvent.class)];
            [eventsFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(eventTime)) ascending:NO]]];
            
            NSError *error;
            NSUInteger eventsCount = [context countForFetchRequest:eventsFetchRequest error:&error];
            if (error) {
                PMSSPushCriticalLog(@"Events count request failed with error: %@ %@", error, error.userInfo);
                return;
            }
            
            if (eventsCount > maxStoredEventCount) {
                [self pruneEvents];
            }
            
            NSArray *events = [context executeFetchRequest:eventsFetchRequest error:&error];
            if (error) {
                PMSSPushCriticalLog(@"Events fetch request failed with error: %@ %@", error, error.userInfo);
                return;
            }
            
            PMSSPushLog(@"Events fetched from Core Data.");
            
            if (events.count > 0) {
                lastSendTime = [[NSDate date] timeIntervalSince1970];
                NSArray *requestBatches = [self batchRequestsFromEvents:events];
                
                PMSSPushLog(@"Sync Analytic Events Started");
                [requestBatches enumerateObjectsUsingBlock:^(NSArray *batchedEvents, NSUInteger idx, BOOL *stop) {
                    [PMSSAnalyticsURLConnection syncAnalyicEvents:batchedEvents
                                                         success:^(NSURLResponse *response, NSData *data) {
                                                             if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                                                                 PMSSPushLog(@"Events successfully synced.");
                                                                 [[PMSSCoreDataManager shared] deleteManagedObjects:batchedEvents];
                                                             } else {
                                                                 PMSSPushLog(@"Events failed to sync.");
                                                             }
                                                         }
                                                         failure:^(NSError *error) {
                                                             PMSSPushLog(@"Events failed to sync.");
                                                         }];
                }];
            }
        }];
    }
}

@end
