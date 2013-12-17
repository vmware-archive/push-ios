//
//  OmniaPushSDK.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-13.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaPushSDK.h"
#import "OmniaPushDebug.h"

@implementation OmniaPushSDK

- (instancetype) init {
    self = [super init];
    if (self) {
        OmniaPushLog(@"OmniaPushSDK:init");
    }
    return self;
}

@end
