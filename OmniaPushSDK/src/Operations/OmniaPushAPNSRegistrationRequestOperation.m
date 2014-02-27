//
//  OmniaPushAPNSRegistrationRequestOperation.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-19.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushDebug.h"

@interface OmniaPushAPNSRegistrationRequestOperation ()

@property (nonatomic, readwrite) OmniaPushRegistrationParameters *parameters;
@property (nonatomic, readwrite) UIApplication *application;

@end

@implementation OmniaPushAPNSRegistrationRequestOperation

- (instancetype) initWithParameters:(OmniaPushRegistrationParameters*)parameters
                        application:(UIApplication*)application
{
    self = [super init];
    if (self) {
        if (parameters == nil) {
            [NSException raise:NSInvalidArgumentException format:@"parameters may not be nil"];
        }
        if (application == nil) {
            [NSException raise:NSInvalidArgumentException format:@"application may not be nil"];
        }
        self.parameters = parameters;
        self.application = application;
    }
    return self;
}

- (void) main
{
    @autoreleasepool {
        OmniaPushCriticalLog(@"Registering for remote notifications with APNS.");
        [self.application registerForRemoteNotificationTypes:self.parameters.remoteNotificationTypes];
    }
}

@end
