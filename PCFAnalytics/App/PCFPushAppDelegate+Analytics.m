//
//  PCFPushAppDelegate+Analytics.m
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import "PCFPushAppDelegate+Analytics.h"
#import "PCFPushDebug.h"
#import "PCFAnalytics.h"

const struct PushNotificationKeys PushNotificationKeys = {
    .pushID   = @"push_id",
    .appState = @"app_state",
};

const struct PushNotificationEvents PushNotificationEvents = {
    .pushReceived = @"event_push_received",
};

@implementation PCFAppDelegate (Analytics)

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self logApplication:application didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self logApplication:application didReceiveRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)logApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    PCFPushLog(@"Received remote notification: %@", userInfo);
    
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
    
    NSMutableDictionary *pushReceivedData = [NSMutableDictionary dictionaryWithCapacity:2];
    [pushReceivedData setObject:appState forKey:PushNotificationKeys.appState];
    
    id pushID = [userInfo objectForKey:PushNotificationKeys.pushID];
    if (pushID) {
        [pushReceivedData setObject:pushID forKey:PushNotificationKeys.pushID];
    }
    [PCFAnalytics logEvent:PushNotificationEvents.pushReceived withParameters:[NSDictionary dictionaryWithDictionary:pushReceivedData]];
}

@end
