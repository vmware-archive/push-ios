//
// Created by DX173-XL on 15-07-22.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushApplicationUtil.h"

@implementation PCFPushApplicationUtil

+ (UIApplicationState) applicationState
{
    return UIApplication.sharedApplication.applicationState;
}

@end