//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFAppDelegate.h"
#import "PCFPushDebug.h"
#import "PCFPush.h"

@interface PCFAppDelegate ()

@end

@implementation PCFAppDelegate

#pragma mark - UIApplicationDelegate Push Notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [PCFPush APNSRegistrationSucceededWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [PCFPush APNSRegistrationFailedWithError:error];
}

@end
