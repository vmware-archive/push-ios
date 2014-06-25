//
//  CFApplicationDelegate.m
//  
//
//  Created by DX123-XL on 2014-03-24.
//
//

#import "PMSSAppDelegate.h"
#import "PMSSPushDebug.h"

@interface PMSSAppDelegate ()

@property (copy) void (^success)(NSData *deviceToken);
@property (copy) void (^failure)(NSError *error);

@end

@implementation PMSSAppDelegate

- (void)setPushRegistrationBlockWithSuccess:(void (^)(NSData *deviceToken))success
                                    failure:(void (^)(NSError *error))failure
{
    if (!success || !failure) {
        [NSException raise:NSInvalidArgumentException format:@"success/failure blocks may not be nil"];
    }
    
    self.success = success;
    self.failure = failure;
}

#pragma mark - UIApplicationDelegate Push Notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    PMSSPushLog(@"Registration successful with APNS. DeviceToken: %@", deviceToken);
    if (self.success) {
        self.success(deviceToken);
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    PMSSPushLog(@"Registration failed with APNS. Error: %@", error);
    if (self.failure) {
        self.failure(error);
    }
}

@end
