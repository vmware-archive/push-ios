//
//  OmniaPushAppDelegateProxy.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-18.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAPNSRegistrationRequest.h"
#import "OmniaPushDebug.h"

@implementation OmniaPushAppDelegateProxy

- (instancetype) initWithAppDelegate:(NSObject<UIApplicationDelegate>*)appDelegate
                 registrationRequest:(NSObject<OmniaPushAPNSRegistrationRequest>*)registrationRequest
{
    if (self) {
        if (appDelegate == nil) {
            [NSException raise:NSInvalidArgumentException format:@"appDelegate may not be nil"];
        }
        if (registrationRequest == nil) {
            [NSException raise:NSInvalidArgumentException format:@"registrationRequest may not be nil"];
        }
        self.appDelegate = appDelegate;
        self.registrationRequest = registrationRequest;
    }
    return self;
}

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types
{
    [self.registrationRequest registerForRemoteNotificationTypes:types];
}

// Delegate methods
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    OmniaPushLog(@"Did register. device token: %@", devToken);
    //const void *devTokenBytes = [devToken bytes];
    //[self sendProviderDeviceToken:devTokenBytes]; // custom method
    [self.appDelegate application:app didRegisterForRemoteNotificationsWithDeviceToken:devToken];
    // TODO - save the registration somehow
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    OmniaPushLog(@"Error in registration. Error: %@", err);
    [self.appDelegate application:app didFailToRegisterForRemoteNotificationsWithError:err];
    // TODO - handle the error somehow
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    OmniaPushLog(@"didReceiveRemoteNotification: %@", userInfo);
}

@end
