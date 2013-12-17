//
//  LogItem.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-17.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LogItem : NSObject

@property NSString *message;
@property NSDate *timestamp;

- (instancetype) initWithMessage:(NSString*)message timestamp:(NSDate*)timestamp;

@end
