//
//  ViewController.m
//  SimpleDemoApp
//
//  Created by Rob Szumlakowski on 2014-02-24.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

// Please supply the release_uuid provided by the Omnia server
static NSString* const kOmniaPushReleaseUuid = @"d7ecb6ac-e27f-406f-a168-198531435621";

// Please supply the release_secret provided by the Omnia server
static NSString* const kOmniaPushReleaseSecret = @"34bfa35d-0d84-4d76-b18b-3908add9fdfd";

// The device alias is developer-defined.  May be empty, but may not be nil.
static NSString* const kOmniaPushDeviceAlias = @"test_device_alias";

@interface ViewController ()

@property (nonatomic) CGRect labelOriginalFrame;

@end

@implementation ViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    // Don't let the view appear under the status bar
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.label.text = @"";
    self.labelOriginalFrame = self.label.frame;

    [self registerForPushNotifications];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedRemoteNotification:) name:kReceivedRemoteNotification object:nil];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) addLogMessage:(NSString*)message
{
    // TODO - make the log scrollable so it can show more items
    self.label.text = [self.label.text stringByAppendingString:[message stringByAppendingString:@"\n\n"]];
    [self fixLabelPosition];
}

- (void) fixLabelPosition
{
    [self.label sizeToFit];
    CGRect labelNewFrame = self.label.frame;
    labelNewFrame.size.width = self.labelOriginalFrame.size.width;
    labelNewFrame.origin = self.labelOriginalFrame.origin;
    self.label.frame = labelNewFrame;
}

- (void) receivedRemoteNotification:(NSNotification*)notification
{
    NSString *message;
    message = notification.userInfo[@"aps"][@"alert"];
    if (message == nil) {
        message = @"Message contents empty";
    }
    [self addLogMessage:[@"Received remote notification: " stringByAppendingString:message]];
}

#pragma mark - Omnia Push Notifications

// This demo application registers for push notifications in the View Controller in order to make it easier
// to display the output on the screen.  It is probably more appropriate for you to register for push notifications
// in your application delegate instead.

- (void) registerForPushNotifications
{
    // Prepare your parameters object
    UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound;
    
    OmniaPushRegistrationParameters *registrationParameters = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:notificationTypes
                                                                                                                    releaseUuid:kOmniaPushReleaseUuid
                                                                                                                  releaseSecret:kOmniaPushReleaseSecret
                                                                                                                    deviceAlias:kOmniaPushDeviceAlias];
    // Call the registration method in the SDK.  The listener is optional.
    // Calling this method more than once during the lifetime of the process will have no effect.
    [OmniaPushSDK registerWithParameters:registrationParameters listener:self];
}

- (void) registrationSucceeded
{
    [self addLogMessage:@"You have been successfully registered for push messages with Omnia."];
}

- (void) registrationFailedWithError:(NSError*)error
{
    [self addLogMessage:[NSString stringWithFormat:@"Registration with Omnia has failed: %@", error.localizedDescription]];
}

@end
