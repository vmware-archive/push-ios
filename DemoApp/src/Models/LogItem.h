//
//  LogItem.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-17.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LOG_ITEM_CELL @"LogItemCell"

@interface LogItem : NSObject

@property (nonatomic) NSString *message;
@property (nonatomic) NSDate *timestamp;

- (instancetype) initWithMessage:(NSString*)message timestamp:(NSDate*)timestamp;
- (NSString*) formattedTimestamp;

@end
