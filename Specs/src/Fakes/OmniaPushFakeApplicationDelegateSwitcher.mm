//
//  OmniaPushFakeApplicationDelegateSwitcher.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-13.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushFakeApplicationDelegateSwitcher.h"
#import "OmniaPushAppDelegateProxy.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface OmniaPushFakeApplicationDelegateSwitcher ()

@property (nonatomic, weak) OmniaSpecHelper *specHelper;

@end

@implementation OmniaPushFakeApplicationDelegateSwitcher

- (instancetype) initWithSpecHelper:(OmniaSpecHelper*)specHelper
{
    self = [super init];
    if (self) {
        self.specHelper = specHelper;
    }
    return self;
}

- (void) switchApplicationDelegate:(id<UIApplicationDelegate>)applicationDelegate inApplication:(UIApplication*)application
{
    self.specHelper.applicationDelegateProxy = (OmniaPushAppDelegateProxy*) applicationDelegate;
}

@end
