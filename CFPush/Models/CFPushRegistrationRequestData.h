//
//  CFPushBackEndRegistrationRequestData.h
//  CFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFPushRegistrationData.h"

@interface CFPushRegistrationRequestData : CFPushRegistrationData

@property NSString *secret;

@end
