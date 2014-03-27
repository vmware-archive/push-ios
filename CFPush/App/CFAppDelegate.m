//
//  OmniaApplicationDelegate.m
//  
//
//  Created by DX123-XL on 2014-03-24.
//
//

#import "CFAppDelegate.h"
#import "CFPushDebug.h"

@interface CFAppDelegate ()

@property NSObject<UIApplicationDelegate> *originalApplicationDelegate;
@property (copy) void (^success)(NSData *devToken);
@property (copy) void (^failure)(NSError *error);

@end

@implementation CFAppDelegate

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
    CFPushLog(@"Registration successful with APNS. DeviceToken: %@", devToken);
    if (self.success) {
        self.success(devToken);
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    CFPushLog(@"Registration failed with APNS. Error: %@", error);
    if (self.failure) {
        self.failure(error);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    CFPushLog(@"Received remote notification: %@", userInfo);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    CFPushLog(@"Received remote notification: %@", userInfo);
}

@end
