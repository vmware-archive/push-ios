//
//  LogItem.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-17.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "LogItem.h"

@interface LogItem ()

@property (nonatomic) NSString *_formattedTimestamp;

@end

@implementation LogItem

- (instancetype) initWithMessage:(NSString*)message timestamp:(NSDate*)timestamp {
    self = [super init];
    if (self) {
        self.message = message;
        self.timestamp = timestamp;
    }
    return self;
}

- (NSString*) formattedTimestamp {
    
    if (self._formattedTimestamp != nil) {
        return self._formattedTimestamp;
    }
    
    if (self.timestamp == nil) {
        return nil;
    }
    
    NSDateFormatter *dateFormatter = [LogItem getDateFormatter];
    self._formattedTimestamp = [dateFormatter stringFromDate:self.timestamp];
    return self._formattedTimestamp;
}

+ (NSDateFormatter*) getDateFormatter {
    static NSDateFormatter *dateFormatter;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    }
    return dateFormatter;
}

@end
