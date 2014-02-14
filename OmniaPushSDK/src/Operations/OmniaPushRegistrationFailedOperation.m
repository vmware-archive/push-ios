//
//  OmniaPushRegistrationFailedOperation.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-08.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushRegistrationFailedOperation.h"
#import "OmniaPushOperationQueueProvider.h"
#import "OmniaPushRegistrationListener.h"
#import "OmniaPushDebug.h"

@interface OmniaPushRegistrationFailedOperation ()

@property (nonatomic, readwrite) UIApplication *application;
@property (nonatomic, weak, readwrite) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic, readwrite) NSError *error;
@property (nonatomic, weak, readwrite) id<OmniaPushRegistrationListener> listener;

@end

@implementation OmniaPushRegistrationFailedOperation

- (instancetype) initWithApplication:(UIApplication*)application
                 applicationDelegate:(id<UIApplicationDelegate>)applicationDelegate
                               error:(NSError*)error
                            listener:(id<OmniaPushRegistrationListener>)listener
{
    self = [super init];
    if (self) {
        if (application == nil) {
            [NSException raise:NSInvalidArgumentException format:@"application may not be nil"];
        }
        if (applicationDelegate == nil) {
            [NSException raise:NSInvalidArgumentException format:@"applicationDelegate may not be nil"];
        }
        if (error == nil) {
            [NSException raise:NSInvalidArgumentException format:@"error may not be nil"];
        }
        self.application = application;
        self.applicationDelegate = applicationDelegate;
        self.error = error;
        self.listener = listener;
    }
    return self;
}

- (void) main
{
    @autoreleasepool {
        
        OmniaPushLog(@"Error in registration. Error: \"%@\".", self.error.localizedDescription);
        
        [[OmniaPushOperationQueueProvider mainQueue] addOperationWithBlock:^{
            if ([self.applicationDelegate respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)]) {
                [self.applicationDelegate application:self.application didFailToRegisterForRemoteNotificationsWithError:self.error];
            }
            if (self.listener) {
                [self.listener registrationFailedWithError:self.error];
            }
        }];
    }
}

@end
