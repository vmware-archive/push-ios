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
#import "PCFParameters.h"
#import "PCFPushSDK.h"
#import "PCFSDK+Analytics.h"

@interface AppDelegate ()

@property (nonatomic) BOOL registered;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:[Settings defaults]];
    
    [self initializeSDK];
    return YES;
}

- (void)initializeSDK
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    static BOOL usePlist = YES;
    PCFParameters *parameters;
    [PCFSDK setAnalyticsEnabled:YES];
    if (usePlist) {
        parameters = [PCFParameters defaultParameters];
        
    } else {
        //PCFParameters configured in code
        parameters = [Settings registrationParameters];
        NSString *message = [NSString stringWithFormat:@"Initializing library with parameters: releaseUUID: \"%@\" releaseSecret: \"%@\" deviceAlias: \"%@\".",
                             parameters.variantUUID,
                             parameters.releaseSecret,
                             parameters.pushDeviceAlias];
        PCFPushLog(message);
    }
    
    [PCFPushSDK setRegistrationParameters:parameters];
#warning - TODO integrate analytics into demo app
    [PCFPushSDK setCompletionBlockWithSuccess:^{
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

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    PCFPushLog(@"FetchCompletionHandler Received message:");
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    application.applicationIconBadgeNumber = 0;
}

#pragma mark - UIApplicationDelegate Push Notification Callback

- (void) application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    PCFPushLog(@"Received message: didRegisterForRemoteNotificationsWithDeviceToken:");
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    PCFPushLog(@"Received message: didFailToRegisterForRemoteNotificationsWithError:");
}

@end
