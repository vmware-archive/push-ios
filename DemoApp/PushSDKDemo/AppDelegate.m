//
//  AppDelegate.m
//  DemoApp
//
//  Created by Rob Szumlakowski on 2013-12-13.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "AppDelegate.h"
#import "Settings.h"
#import "PCFPushDebug.h"
#import "PCFPushParameters.h"
#import "PCFPushSDK.h"

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
    
    [self initializeSDK];
    return YES;
}

- (void)initializeSDK
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    PCFPushParameters *parameters = [Settings registrationParameters];
    NSString *message = [NSString stringWithFormat:@"Initializing library with parameters: releaseUUID: \"%@\" releaseSecret: \"%@\" deviceAlias: \"%@\".",
                         parameters.variantUUID,
                         parameters.releaseSecret,
                         parameters.deviceAlias];
    PCFPushLog(message);
    
    [PCFPushSDK registerWithParameters:parameters success:^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        PCFPushLog(@"Application received callback \"registrationSucceeded\".");
        
    } failure:^(NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        PCFPushLog(@"Application received callback \"registrationFailedWithError:\". Error: \"%@\"", error.localizedDescription);
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    PCFPushLog(@"Received message: %@", userInfo[@"aps"][@"alert"]);
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    application.applicationIconBadgeNumber = 0;
}

#pragma mark - UIApplicationDelegate Push Notification Callback

- (void) application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{
    PCFPushLog(@"Received message: didRegisterForRemoteNotificationsWithDeviceToken:");
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    PCFPushLog(@"Received message: didFailToRegisterForRemoteNotificationsWithError:");
}

@end
