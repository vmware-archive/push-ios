//
//  PCFPushAppDelegate+Analytics.m
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import "PCFPushAppDelegate+Analytics.h"
#import "PCFPushDebug.h"

@implementation PCFAppDelegate (Analytics)

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    PCFPushLog(@"Received remote notification: %@", userInfo);
    [PCFAnalytics logApplication:application didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    PCFPushLog(@"Received remote notification: %@", userInfo);
    [PCFAnalytics logApplication:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

@end
