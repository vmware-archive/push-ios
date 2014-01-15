//
//  OmniaPushApplicationDelegateSwitcherProvider.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-13.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushApplicationDelegateSwitcherProvider.h"
#import "OmniaPushApplicationDelegateSwitcherImpl.h"

static NSObject<OmniaPushApplicationDelegateSwitcher>* _switcher = nil;

@implementation OmniaPushApplicationDelegateSwitcherProvider

+ (NSObject<OmniaPushApplicationDelegateSwitcher>*) switcher
{
    if (_switcher == nil) {

    }
    return _switcher;
}

+ (void) setSwitcher:(NSObject<OmniaPushApplicationDelegateSwitcher>*) switcher
{
    _switcher = switcher;
}

@end
