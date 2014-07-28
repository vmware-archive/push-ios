//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSAppDelegate.h"
#import "MSSMapping.h"

const struct PushNotificationKeys {
    MSS_STRUCT_STRING *pushID;
    MSS_STRUCT_STRING *appState;
} PushNotificationKeys;

const struct PushNotificationEvents {
    MSS_STRUCT_STRING *pushReceived;
} PushNotificationEvents;


@interface MSSAppDelegate (Analytics)

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler NS_AVAILABLE_IOS(7_0);

@end
