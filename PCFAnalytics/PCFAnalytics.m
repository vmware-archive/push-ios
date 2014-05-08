//
//  PCFAnalytics.m
//  
//
//  Created by DX123-XL on 2014-04-01.
//
//

#import <UIKit/UIKit.h>

#import "PCFAnalytics.h"
#import "PCFPushDebug.h"
#import "PCFAnalyticEvent.h"
#import "PCFCoreDataManager.h"
#import "PCFPersistentStorage+Analytics.h"
#import "PCFAnalyticsURLConnection.h"
#import "PCFHardwareUtil.h"
#import "PCFNotifications.h"

#define PCF_ADD_OBSERVER(observer_selector, notification_name) [[NSNotificationCenter defaultCenter] addObserver:self selector:observer_selector name:notification_name object:nil];

static NSTimeInterval minSecondsBetweenSends = 60.0f;
static NSUInteger maxStoredEventCount = 1000;
static NSUInteger maxBatchSize = 100;
static NSTimeInterval lastSendTime;


const struct EventTypes {
    PCF_STRUCT_STRING *error;
    PCF_STRUCT_STRING *active;
    PCF_STRUCT_STRING *inactive;
    PCF_STRUCT_STRING *backgrounded;
    PCF_STRUCT_STRING *foregrounded;
    PCF_STRUCT_STRING *registered;
    PCF_STRUCT_STRING *unregistered;
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
    PCF_STRUCT_STRING *errorID;
    PCF_STRUCT_STRING *errorMessage;
} ErrorEventKeys;

static const struct ErrorEventKeys ErrorEventKeys = {
    .errorID        = @"id",
    .errorMessage   = @"message",
};


static const struct ErrorType {
    PCF_STRUCT_STRING *exception;
    PCF_STRUCT_STRING *error;
} ErrorType;

static const struct ErrorType ErrorType = {
    .exception = @"exception",
    .error          = @"error",
};

@implementation PCFAnalytics

+ (void)load
{
    PCF_ADD_OBSERVER(@selector(didEnterBackground), UIApplicationDidEnterBackgroundNotification);
    PCF_ADD_OBSERVER(@selector(willEnterForground), UIApplicationWillEnterForegroundNotification);
    PCF_ADD_OBSERVER(@selector(didBecomeActive), UIApplicationDidBecomeActiveNotification);
    PCF_ADD_OBSERVER(@selector(willResignActive), UIApplicationWillResignActiveNotification);
    PCF_ADD_OBSERVER(@selector(registrationSuccessful), PCFPushRegistrationSuccessNotification);
    PCF_ADD_OBSERVER(@selector(unregisterSuccessful), PCFPushUnregisterNotification);
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
    PCFPushLog(@"Enter Background - Logging event.");
    [self logEvent:EventTypes.backgrounded];
    [self sendAnalytics];
}

+ (void)willEnterForground
{
    PCFPushLog(@"Will Enter Foreground - Logging event.");
    [self logEvent:EventTypes.foregrounded];
}

+ (void)didBecomeActive
{
    PCFPushLog(@"Did Become Active - Logging event.");
    static NSDictionary *params;
    if (!params) {
        NSString *shortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        params = @{
                   @"application_version" : shortVersion?:@"NA",
                   @"os" : [PCFHardwareUtil operatingSystem],
                   @"os_version" : [PCFHardwareUtil operatingSystemVersion],
                   @"device_manufacturer" : [PCFHardwareUtil deviceManufacturer],
                   @"device_model" : [PCFHardwareUtil deviceModel],
                   };
    }
    [self logEvent:EventTypes.active withParameters:params];
}

+ (void)willResignActive
{
    PCFPushLog(@"Will Resign Active - Logging event.");
    [self logEvent:EventTypes.inactive];
}

+ (void)registrationSuccessful
{
    PCFPushLog(@"Push Registration Successful - Logging event.");
    [self logEvent:EventTypes.registered];
}

+ (void)unregisterSuccessful
{
    PCFPushLog(@"Push Unregistration Successful - Logging event.");
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
    if (![PCFPersistentStorage analyticsEnabled]) {
        PCFPushLog(@"Analytics disabled. Event will not be logged.");
        return;
    }
    
    NSManagedObjectContext *context = [[PCFCoreDataManager shared] managedObjectContext];
    [context performBlock:^{
        [self insertIntoContext:context eventWithType:eventName data:parameters];
        NSError *error;
        if (![context save:&error]) {
            PCFPushCriticalLog(@"Managed Object Context failed to save: %@ %@", error, error.userInfo);
        }
    }];
}

+ (void)insertIntoContext:(NSManagedObjectContext *)context
            eventWithType:(NSString *)eventType
                     data:(NSDictionary *)eventData
{
    NSEntityDescription *description = [NSEntityDescription entityForName:NSStringFromClass(PCFAnalyticEvent.class) inManagedObjectContext:context];
    PCFAnalyticEvent *event = [[PCFAnalyticEvent alloc] initWithEntity:description insertIntoManagedObjectContext:context];
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
    if (![PCFPersistentStorage analyticsEnabled]) {
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

@end
