//
//  PCFPushAppDelegate+Analytics.h
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import "PCFAppDelegate.h"
#import "PCFAnalytics.h"

@interface PCFAppDelegate (Analytics)

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler NS_AVAILABLE_IOS(7_0);

@end
