//
//  LogItem.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-17.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "LogItem.h"

@implementation LogItem

- (instancetype) initWithMessage:(NSString*)message timestamp:(NSDate*)timestamp {
    self = [super init];
    if (self) {
        self.message = message;
        self.timestamp = timestamp;
    }
    return self;
}

@end
