//
//  SettingsTableViewController.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-31.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "OmniaPushPersistentStorage.h"
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
    self.versionLabel.text = [NSString stringWithFormat:@"Version %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
}


- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self saveSettings];
}

- (IBAction) clearRegistrationPressed:(id)sender
{
    // TODO: WRITE ME!
}

- (IBAction) resetToDefaults:(id)sender
{
    [Settings resetToDefaults];
    [self loadSettings];
}

- (void) loadSettings
{
    self.releaseUuidTextField.text = [Settings loadReleaseUuid];
    self.releaseSecretTextField.text = [Settings loadReleaseSecret];
    self.deviceAliasTextField.text = [Settings loadDeviceAlias];
}

- (void) saveSettings
{
    [Settings saveReleaseUuid:self.releaseUuidTextField.text];
    [Settings saveReleaseSecret:self.releaseSecretTextField.text];
    [Settings saveDeviceAlias:self.deviceAliasTextField.text];
}

@end
