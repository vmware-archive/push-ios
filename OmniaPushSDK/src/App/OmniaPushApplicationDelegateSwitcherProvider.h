//
//  OmniaPushApplicationDelegateSwitcherProvider.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-13.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OmniaPushApplicationDelegateSwitcher;

@interface OmniaPushApplicationDelegateSwitcherProvider : NSObject

+ (NSObject<OmniaPushApplicationDelegateSwitcher>*) switcher;
+ (void) setSwitcher:(NSObject<OmniaPushApplicationDelegateSwitcher>*) switcher;

@end
