//
//  LogItemCell.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-17.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "LogItemCell.h"
#import "LogItem.h"

#define PADDING 6.0f
static CGFloat MESSAGE_LABEL_X = PADDING;
static CGFloat MESSAGE_LABEL_Y = PADDING;
static CGFloat MESSAGE_LABEL_FONT_SIZE = 14.0f;
static CGFloat MESSAGE_LABEL_MAX_HEIGHT = 300.0f;
static CGFloat TIMESTAMP_LABEL_X = PADDING;
static CGFloat TIMESTAMP_LABEL_HEIGHT = 10.0f;
static CGFloat TIMESTAMP_LABEL_WIDTH = 304.0f;
static UIFont *labelFont = nil;

@implementation LogItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // nothing to do
    }
    return self;
}

- (void) setLogItem:(LogItem *)logItem containerSize:(CGSize)containerSize; {
    self.logItem = logItem;
    self.labelTimestamp.text = logItem.formattedTimestamp;
    self.labelMessage.text = logItem.message;
    self.labelMessage.font = labelFont;
    self.labelMessage.numberOfLines = 0;
    CGRect messageFrame = [self frameForLabelWithText:logItem.message containerSize:containerSize];
    self.labelMessage.frame = messageFrame;
    CGRect timestampFrame = CGRectMake(TIMESTAMP_LABEL_X, messageFrame.size.height + PADDING * 2.0f, TIMESTAMP_LABEL_WIDTH, TIMESTAMP_LABEL_HEIGHT);
    self.labelTimestamp.frame = timestampFrame;
    self.backgroundColor = logItem.colour;
}

- (CGRect) frameForLabelWithText:(NSString*)text containerSize:(CGSize)containerSize {
    CGFloat x = MESSAGE_LABEL_X;
    CGFloat y = MESSAGE_LABEL_Y;
    CGFloat width = containerSize.width - x - PADDING;
    CGFloat height = [LogItemCell heightForLabelWithText:text containerSize:containerSize];
    CGRect frame = CGRectMake(x, y, width, height);
    return frame;
}

+ (CGFloat) heightForCellWithText:(NSString*)text containerSize:(CGSize)containerSize {
    CGFloat timestampLabelHeight = TIMESTAMP_LABEL_HEIGHT;
    CGFloat messageHeight = [LogItemCell heightForLabelWithText:text containerSize:containerSize];
    return timestampLabelHeight + messageHeight + PADDING * 3;
}

+ (CGFloat) heightForLabelWithText:(NSString*)text containerSize:(CGSize)containerSize {
    
    // Initialize font once
    if (labelFont == nil) {
        labelFont = [UIFont systemFontOfSize:MESSAGE_LABEL_FONT_SIZE];
    }
    
    CGSize maxSize = CGSizeMake(containerSize.width - MESSAGE_LABEL_X - PADDING, MESSAGE_LABEL_MAX_HEIGHT);
    NSDictionary *attr = @{NSFontAttributeName:labelFont};
    CGRect r = [text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attr context:nil];    
    
    return r.size.height + 1;
}

@end
