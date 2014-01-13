//
//  OmniaPushRegistrationCompleteOperation.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-08.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaPushRegistrationListener.h"
#import "OmniaPushDebug.h"

@interface OmniaPushRegistrationCompleteOperation ()

@property (nonatomic) UIApplication *application;
@property (nonatomic, weak) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic) NSData *deviceToken;

@end

@implementation OmniaPushRegistrationCompleteOperation

- (instancetype) initWithApplication:(UIApplication*)application
                 applicationDelegate:(id<UIApplicationDelegate>)applicationDelegate
                         deviceToken:(NSData*)deviceToken
{
    self = [super init];
    if (self) {
        self.application = application;
        self.applicationDelegate = applicationDelegate;
        self.deviceToken = deviceToken;
    }
    return self;
}

- (void) main
{
    @autoreleasepool {
        OmniaPushLog(@"Registration with APNS successful. device token: %@", self.deviceToken);
        
        //const void *devTokenBytes = [devToken bytes];
        //[self sendProviderDeviceToken:devTokenBytes]; // custom method
        
        // TODO - call on main thread
        [self.applicationDelegate application:self.application didRegisterForRemoteNotificationsWithDeviceToken:self.deviceToken];
        
//        if (self.listener) {
//            [self.listener application:self.application didRegisterForRemoteNotificationsWithDeviceToken:self.deviceToken];
//        }
        // TODO - save the registration somehow
    }
}

@end
