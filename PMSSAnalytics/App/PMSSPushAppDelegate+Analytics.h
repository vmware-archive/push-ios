//
//  PMSSPushAppDelegate+Analytics.h
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import "PMSSAppDelegate.h"
#import "PMSSMapping.h"

const struct PushNotificationKeys {
    PMSS_STRUCT_STRING *pushID;
    PMSS_STRUCT_STRING *appState;
} PushNotificationKeys;

const struct PushNotificationEvents {
    PMSS_STRUCT_STRING *pushReceived;
} PushNotificationEvents;


@interface PMSSAppDelegate (Analytics)

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler NS_AVAILABLE_IOS(7_0);

@end
