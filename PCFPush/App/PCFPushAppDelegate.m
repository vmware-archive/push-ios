//
//  CFApplicationDelegate.m
//  
//
//  Created by DX123-XL on 2014-03-24.
//
//

#import "PCFPushAppDelegate.h"
#import "PCFPushDebug.h"

@interface PCFPushAppDelegate ()

@property NSObject<UIApplicationDelegate> *originalApplicationDelegate;
@property (copy) void (^success)(NSData *devToken);
@property (copy) void (^failure)(NSError *error);

@end

@implementation PCFPushAppDelegate

- (void)setRegistrationBlockWithSuccess:(void (^)(NSData *devToken))success
                                failure:(void (^)(NSError *error))failure
{
    if (!success || !failure) {
        [NSException raise:NSInvalidArgumentException format:@"success/failure blocks may not be nil"];
    }
    
    self.success = success;
    self.failure = failure;
}

#pragma mark - UIApplicationDelegate Push Notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{
    PCFPushLog(@"Registration successful with APNS. DeviceToken: %@", devToken);
    if (self.success) {
        self.success(devToken);
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    PCFPushLog(@"Registration failed with APNS. Error: %@", error);
    if (self.failure) {
        self.failure(error);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    PCFPushLog(@"Received remote notification: %@", userInfo);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    PCFPushLog(@"Received remote notification: %@", userInfo);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    PCFPushLog(@"Received local notification: %@", notification);
}

@end
