//
//  OmniaPushAPNSRegistrationRequestOperation.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-19.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaPushAPNSRegistrationRequestOperation.h"

@interface OmniaPushAPNSRegistrationRequestOperation ()

@property (nonatomic, readwrite, assign) UIRemoteNotificationType notificationTypes;
@property (nonatomic, readwrite) UIApplication *application;

@end

@implementation OmniaPushAPNSRegistrationRequestOperation

- (instancetype) initForRegistrationForRemoteNotificationTypes:(UIRemoteNotificationType)types
                                                   application:(UIApplication*)application
{
    self = [super init];
    if (self) {
        if (application == nil) {
            [NSException raise:NSInvalidArgumentException format:@"application may not be nil"];
        }
        self.notificationTypes = types;
        self.application = application;
    }
    return self;
}

// TODO: should this class also accept the UIApplication to use?  It would be more dependency-injectiony.

- (void) main
{
    @autoreleasepool {
        [self.application registerForRemoteNotificationTypes:self.notificationTypes];
    }
}

@end
