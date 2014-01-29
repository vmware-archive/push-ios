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
@property (nonatomic, readwrite) NSData *apnsDeviceToken;

@end

@implementation OmniaPushRegistrationCompleteOperation

- (instancetype) initWithApplication:(UIApplication*)application
                 applicationDelegate:(id<UIApplicationDelegate>)applicationDelegate
                     apnsDeviceToken:(NSData*)apnsDeviceToken
{
    self = [super init];
    if (self) {
        if (application == nil) {
            [NSException raise:NSInvalidArgumentException format:@"application may not be nil"];
        }
        if (applicationDelegate == nil) {
            [NSException raise:NSInvalidArgumentException format:@"applicationDelegate may not be nil"];
        }
        if (apnsDeviceToken == nil) {
            [NSException raise:NSInvalidArgumentException format:@"apnsDeviceToken may not be nil"];
        }
        self.application = application;
        self.applicationDelegate = applicationDelegate;
        self.apnsDeviceToken = apnsDeviceToken;
    }
    return self;
}

- (void) main
{
    @autoreleasepool {
        
        OmniaPushLog(@"Registration complete.");
        
        [[OmniaPushOperationQueueProvider mainQueue] addOperationWithBlock:^{
            [self.applicationDelegate application:self.application didRegisterForRemoteNotificationsWithDeviceToken:self.apnsDeviceToken];
        }];
    }
}

@end
