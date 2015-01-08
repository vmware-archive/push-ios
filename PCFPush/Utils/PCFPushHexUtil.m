//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushHexUtil.h"

@implementation PCFPushHexUtil

+ (NSString *)hexDumpForData:(NSData *)data
{
    if (data == nil) return nil;
    
    NSUInteger resultLength = data.length * 2;
    NSMutableString *result = [NSMutableString stringWithCapacity:resultLength];
    const unsigned char *bytes = (const unsigned char*)[data bytes];

    for (NSUInteger i = 0; i < data.length; i += 1) {
        [result appendFormat:@"%02X", bytes[i]];
    }
    
    return result;
}

@end
