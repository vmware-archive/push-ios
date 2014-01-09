//
//  OmniaPushRegistrationFailedOperation.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-08.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushRegistrationFailedOperation.h"
#import "OmniaPushRegistrationListener.h"
#import "OmniaPushDebug.h"

@interface OmniaPushRegistrationFailedOperation ()

@property (nonatomic) UIApplication *application;
@property (nonatomic, weak) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic, weak) id<OmniaPushRegistrationListener> listener;
@property (nonatomic) NSError *error;

@end

@implementation OmniaPushRegistrationFailedOperation

- (instancetype) initWithApplication:(UIApplication*)application
                 applicationDelegate:(id<UIApplicationDelegate>)applicationDelegate
                            listener:(id<OmniaPushRegistrationListener>)listener
                               error:(NSError*)error
{
    self = [super init];
    if (self) {
        self.application = application;
        self.applicationDelegate = applicationDelegate;
        self.listener = listener;
        self.error = error;
    }
    return self;
}

- (void) main
{
    @autoreleasepool {
        
        OmniaPushLog(@"Error in registration with APNS. Error: %@", self.error);
        [self.applicationDelegate application:self.application didFailToRegisterForRemoteNotificationsWithError:self.error];
        if (self.listener) {
            [self.listener application:self.application didFailToRegisterForRemoteNotificationsWithError:self.error];
        }
        // TODO - handle the error somehow
    }
}

@end
