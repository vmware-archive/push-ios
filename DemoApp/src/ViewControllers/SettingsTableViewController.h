//
//  SettingsTableViewController.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-31.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsTableViewController : UITableViewController

@property (nonatomic) IBOutlet UITextField* releaseUuidTextField;
@property (nonatomic) IBOutlet UITextField* releaseSecretTextField;
@property (nonatomic) IBOutlet UITextField* deviceAliasTextField;

- (IBAction) clearRegistrationPressed:(id)sender;
- (IBAction) resetToDefaults:(id)sender;

@end
