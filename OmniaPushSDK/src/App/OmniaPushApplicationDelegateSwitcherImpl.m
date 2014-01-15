//
//  OmniaPushApplicationDelegateSwitcherImpl.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-13.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushApplicationDelegateSwitcherImpl.h"
#import "OmniaPushApplicationDelegateSwitcher.h"

@implementation OmniaPushApplicationDelegateSwitcherImpl

- (void) switchApplicationDelegate:(id<UIApplicationDelegate>)applicationDelegate inApplication:(UIApplication*)application
{
    @synchronized(self) {
        application.delegate = applicationDelegate;
    }
}

@end
