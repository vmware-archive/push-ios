//
//  ViewController.h
//  SimpleDemoApp
//
//  Created by Rob Szumlakowski on 2014-02-24.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OmniaPushSDK/OmniaPushSDK.h>

@interface ViewController : UIViewController<OmniaPushRegistrationListener>

@property (nonatomic) IBOutlet UILabel *label;

@end
