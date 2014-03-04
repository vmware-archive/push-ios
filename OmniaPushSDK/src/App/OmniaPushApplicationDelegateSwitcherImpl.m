//
//  OmniaPushApplicationDelegateSwitcherImpl.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-13.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushApplicationDelegateSwitcherImpl.h"
#import "OmniaPushApplicationDelegateSwitcher.h"

@implementation OmniaPushApplicationDelegateSwitcherImpl

- (void) switchApplicationDelegate:(NSObject<UIApplicationDelegate> *)applicationDelegate inApplication:(UIApplication *)application
{
    @synchronized(self) {
        application.delegate = applicationDelegate;
    }
}

@end
