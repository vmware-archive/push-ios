//
//  SettingsTableViewController.m
//  MSSPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-31.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "MSSPersistentStorage+Push.h"
#import "Settings.h"

@implementation SettingsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadSettings];
    
#if DEBUG
    NSString *buildType = @"Debug";
#else
    NSString *buildType = @"Release";
#endif
    
    self.versionLabel.text = [NSString stringWithFormat:@"Version %@ - %@ Build", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], buildType];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self saveSettings];
}

- (IBAction)clearRegistrationPressed:(id)sender
{
    [MSSPersistentStorage resetPushPersistedValues];
    [self showAlert:@"Registration cleared."];
}

- (IBAction) resetToDefaults:(id)sender
{
    [Settings resetToDefaults];
    [self loadSettings];
    [self showAlert:@"Settings reset to defaults."];
}

- (void) loadSettings
{
    self.releaseUuidTextField.text = [Settings variantUUID];
    self.releaseSecretTextField.text = [Settings releaseSecret];
    self.deviceAliasTextField.text = [Settings deviceAlias];
}

- (void) saveSettings
{
    [Settings setVariantUUID:self.releaseUuidTextField.text];
    [Settings setReleaseSecret:self.releaseSecretTextField.text];
    [Settings setDeviceAlias:self.deviceAliasTextField.text];
}

- (void)showAlert:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:message message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
}

@end
