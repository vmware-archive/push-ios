//
//  SettingsTableViewController.h
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-31.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsTableViewController : UITableViewController

@property (nonatomic) IBOutlet UITextField* releaseUuidTextField;
@property (nonatomic) IBOutlet UITextField* releaseSecretTextField;
@property (nonatomic) IBOutlet UITextField* deviceAliasTextField;
@property (nonatomic) IBOutlet UILabel *versionLabel;

- (IBAction) clearRegistrationPressed:(id)sender;
- (IBAction) resetToDefaults:(id)sender;

@end
