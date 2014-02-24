//
//  LogItem.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-17.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "LogItem.h"

NSString *const LOG_ITEM_CELL = @"LogItemCell";

static int currentBaseRowColour = 0;
static int numItems = 0;

@interface LogItem ()

@property (nonatomic) NSString *_formattedTimestamp;

@end

@implementation LogItem

- (instancetype) initWithMessage:(NSString*)message timestamp:(NSDate*)timestamp {
    self = [super init];
    if (self) {
        self.message = message;
        self.timestamp = timestamp;
        self.colour = [self getColour];
    }
    return self;
}

- (UIColor*) getColour {
    
    static NSArray *darkBaseRowColours = nil;
    if (darkBaseRowColours == nil) {
        darkBaseRowColours = @[[UIColor colorWithRed:0.85f green:0.75f blue:0.75f alpha:1.0f],
                           [UIColor colorWithRed:0.75f green:0.85f blue:0.75f alpha:1.0f],
                           [UIColor colorWithRed:0.75f green:0.75f blue:0.85f alpha:1.0f]];
    }
    
    static NSArray *lightBaseRowColours = nil;
    if (lightBaseRowColours == nil) {
        lightBaseRowColours = @[[UIColor colorWithRed:0.95f green:0.8f blue:0.8f alpha:1.0f],
                               [UIColor colorWithRed:0.8f green:0.95f blue:0.8f alpha:1.0f],
                               [UIColor colorWithRed:0.8f green:0.8f blue:0.95f alpha:1.0f]];
    }

    numItems += 1;
    if (numItems % 2) {
        return darkBaseRowColours[currentBaseRowColour % darkBaseRowColours.count];
    } else {
        return lightBaseRowColours[currentBaseRowColour % lightBaseRowColours.count];
    }
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

+ (void) updateBaseColour {
    currentBaseRowColour += 1;
}

@end
