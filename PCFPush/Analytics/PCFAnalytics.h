//
//  PCFAnalytics.h
//  
//
//  Created by DX123-XL on 2014-04-01.
//
//

#import <Foundation/Foundation.h>

@interface PCFAnalytics : NSObject

+ (void)logApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;

+ (void)logApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

@end
