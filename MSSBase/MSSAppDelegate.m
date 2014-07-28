//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSAppDelegate.h"
#import "MSSPushDebug.h"

@interface MSSAppDelegate ()

@property (copy) void (^success)(NSData *deviceToken);
@property (copy) void (^failure)(NSError *error);

@end

@implementation MSSAppDelegate

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
    MSSPushLog(@"Registration successful with APNS. DeviceToken: %@", deviceToken);
    if (self.success) {
        self.success(deviceToken);
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    MSSPushLog(@"Registration failed with APNS. Error: %@", error);
    if (self.failure) {
        self.failure(error);
    }
}

@end
