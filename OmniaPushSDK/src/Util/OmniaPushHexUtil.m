//
//  OmniaPushHexUtil.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushHexUtil.h"

@implementation OmniaPushHexUtil

+ (NSString*) hexDumpForData:(NSData*)data
{
    if (data == nil) return nil;
    
    NSUInteger resultLength = data.length * 2;
    NSMutableString *result = [NSMutableString stringWithCapacity:resultLength];
    const unsigned char* bytes = (const unsigned char*)[data bytes];

    for (NSUInteger i = 0; i < data.length; i += 1) {
        [result appendFormat:@"%02X", bytes[i]];
    }
    
    return result;
}

@end
