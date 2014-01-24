//
//  OmniaPushRegistrationCompleteOperation.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-08.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaPushOperationQueueProvider.h"
#import "OmniaPushDebug.h"

@interface OmniaPushRegistrationCompleteOperation ()

@property (nonatomic, readwrite) UIApplication *application;
@property (nonatomic, weak, readwrite) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic, readwrite) NSData *deviceToken;

@end

@implementation OmniaPushRegistrationCompleteOperation

- (instancetype) initWithApplication:(UIApplication*)application
                 applicationDelegate:(id<UIApplicationDelegate>)applicationDelegate
                         deviceToken:(NSData*)deviceToken
{
    self = [super init];
    if (self) {
        if (application == nil) {
            [NSException raise:NSInvalidArgumentException format:@"application may not be nil"];
        }
        if (applicationDelegate == nil) {
            [NSException raise:NSInvalidArgumentException format:@"applicationDelegate may not be nil"];
        }
        if (deviceToken == nil) {
            [NSException raise:NSInvalidArgumentException format:@"deviceToken may not be nil"];
        }
        self.application = application;
        self.applicationDelegate = applicationDelegate;
        self.deviceToken = deviceToken;
    }
    return self;
}

- (void) main
{
    @autoreleasepool {
        
        OmniaPushLog(@"Registration with APNS successful. Device token is %@.", self.deviceToken);
        
        [[OmniaPushOperationQueueProvider mainQueue] addOperationWithBlock:^{
            [self.applicationDelegate application:self.application didRegisterForRemoteNotificationsWithDeviceToken:self.deviceToken];
        }];

        // TODO - save the registration somehow.
        // TODO - send device token to back end
    }
}

@end
