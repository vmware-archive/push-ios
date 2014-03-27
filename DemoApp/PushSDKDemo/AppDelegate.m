//
//  AppDelegate.m
//  DemoApp
//
//  Created by Rob Szumlakowski on 2013-12-13.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "AppDelegate.h"
#import "Settings.h"
#import "CFPushDebug.h"

@interface AppDelegate ()

@property (nonatomic) BOOL registered;

@end

@implementation AppDelegate

- (void)dealloc {
    NSLog(@"dealloc");
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:[Settings defaults]];
    
    // Override point for customization after application launch.
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    CFPushLog(@"Received message: %@", userInfo[@"aps"][@"alert"]);
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    application.applicationIconBadgeNumber = 0;
}

#pragma mark - UIApplicationDelegate Push Notification Callback

- (void) application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{

}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    
}

@end
