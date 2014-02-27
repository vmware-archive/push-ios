//
//  OmniaPushFakeApplicationDelegateSwitcher.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-13.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniaPushApplicationDelegateSwitcher.h"
#import "OmniaSpecHelper.h"

@interface OmniaPushFakeApplicationDelegateSwitcher : NSObject<OmniaPushApplicationDelegateSwitcher>

- (instancetype) initWithSpecHelper:(OmniaSpecHelper*)specHelper;

@end
