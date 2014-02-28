//
//  AppDelegate.m
//  SimpleDemoApp
//
//  Created by Rob Szumlakowski on 2014-02-24.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "AppDelegate.h"

NSString *kReceivedRemoteNotification = @"org.omnia.pushsdk.SimpleDemoApp.ReceivedRemoteNotification";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    // Notify the view controller that a remote notification has been received.
    [[NSNotificationCenter defaultCenter] postNotificationName:kReceivedRemoteNotification object:nil userInfo:userInfo];
}

@end
