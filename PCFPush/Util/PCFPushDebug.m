//
//  PCFPushDebug.m
//  Xtreme-Monitoring
//
//  Created by Rob Szumlakowski on 2013-08-22.
//  Copyright (c) 2013 Xtreme Labs. All rights reserved.
//
// Based on XLDebug by Christopher Larsen, see license below:

/* Copyright (c) 2013 Xtreme Labs Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

////////////////////////////////////////////////////////////////////////////////////////////////
//
//  PCFPushDebug.m
//
//  Created by Christopher Larsen
//
////////////////////////////////////////////////////////////////////////////////////////////////

#import "PCFPushDebug.h"

static NSInteger MAX_COLUMN_WIDTH = 90;   // Limits the maximum number of characters used in the console display for function name


BOOL flareHasFired = NO;
BOOL disableLogging = NO;
NSInteger timesRemainingBeforeBreak = 0;
PCFPushLogListener listener = nil;


@implementation PCFPushDebug

+ (void)log:(NSString *)output {
    if (!disableLogging) {
        NSLog(@"%@", output);
    }
    if (listener) {
        listener(output, [NSDate date]);
    }
}

+ (void)disableLogging:(BOOL)loggingDisabled {
    disableLogging = loggingDisabled;
}

+ (void)log:(char *)fileName
 lineNumber:(int)lineNumber
   function:(const char *)stringFunction
     thread:(NSThread*)thread
 isCritical:(BOOL)isCritical
      input:(NSString *)input, ...
{
    if (disableLogging == YES && listener == nil) {
        return;
    }
    
    va_list argList;
    NSString *formatStr;
    
    va_start(argList, input);
    formatStr = [[NSString alloc] initWithFormat:input arguments:argList];
    va_end(argList);
    
    NSString *stringLine = [NSString stringWithFormat:@"<%3.0d>(T0x%08lx-%@): ", lineNumber, (unsigned long) thread, [thread isMainThread] ? @"MN" : @"BG"];
    
    NSMutableString *string_out = [NSMutableString stringWithString:[NSString stringWithFormat:@"%s", stringFunction]];
    
    while (string_out.length > MAX_COLUMN_WIDTH - stringLine.length) [string_out deleteCharactersInRange:NSMakeRange(string_out.length - 1, 1)];
    
    [string_out appendString:stringLine];
    [string_out appendString:formatStr];

    BOOL isDebug = NO;
    #if DEBUG
    isDebug = YES;
    #endif
    
    if (isDebug || isCritical) {
        if (!disableLogging) {
            NSLog(@"%@", string_out);
        }
    }

    if (listener) {
        listener(formatStr, [NSDate date]);
    }
}

+ (void)error:(char *)fileName
   lineNumber:(int)lineNumber
     function:(const char *)stringFunction
        input:(NSString *)input, ...
{
    if (disableLogging == YES && listener == nil) {
        return;
    }
    
    va_list argList;
    NSString *filePath, *formatStr;
    
    filePath = [[NSString alloc] initWithBytes:fileName length:strlen(fileName) encoding:NSUTF8StringEncoding];
    
    va_start(argList, input);
    formatStr = [[NSString alloc] initWithFormat:input arguments:argList];
    va_end(argList);
    
    NSString *message = [NSString stringWithFormat:@"\n\n ERROR\n  File: %s\n  Line: %d\n  File: %s\n Cause: %@ \n\n", [[filePath lastPathComponent] UTF8String], lineNumber, stringFunction, formatStr];
    [PCFPushDebug log:message];
    
    PCFPushBreakPoint;
    
    exit(1);
}


+ (void)assert:(int)evaluate
        output:(char *)fileName
    lineNumber:(int)lineNumber
      function:(const char *)stringFunction
         input:(NSString *)input, ...
{
    if (evaluate == TRUE) {
        return;
    }
    
    va_list argList;
    NSString *filePath, *formatStr;
    
    filePath = [[NSString alloc] initWithBytes:fileName length:strlen(fileName) encoding:NSUTF8StringEncoding];
    
    va_start(argList, input);
    formatStr = [[NSString alloc] initWithFormat:input arguments:argList];
    va_end(argList);
    
    NSString *stringOut = [NSString stringWithFormat:@"\n\nASSERTION ERROR\n File: %s\n  Line: %d \n%s \n  Cause: %@ \n\n",
                           [[filePath lastPathComponent] UTF8String],
                           lineNumber,
                           stringFunction,
                           formatStr];
    
    [PCFPushDebug log:stringOut];
    
    PCFPushBreakPoint;
    
    exit(1);
}

+ (void)trace:(const char *)stringFunction {
    if (disableLogging == YES && listener == nil) {
        return;
    }
    
    NSString *string_out = [NSString stringWithFormat:@"%s", stringFunction ];
    [PCFPushDebug log:string_out];
}

+ (void)beacon:(NSString *)input, ... {
    NSString *beaconString = [@">>>>>>>>>>>>>>>>>>>>>> Beacon: " stringByAppendingString : input];
    [PCFPushDebug log:@" "];
    [PCFPushDebug log:beaconString];
    [PCFPushDebug log:@" "];
    [NSThread sleepForTimeInterval:1.5];
}

+ (void)flare {
    if (flareHasFired == TRUE) {
        return;
    }
    
    flareHasFired = TRUE;
    [PCFPushDebug log:@" "];
    [PCFPushDebug log:@">>>>>>>>>>>>>>>>>>>>>> Flare"];
    [PCFPushDebug log:@" "];
    [NSThread sleepForTimeInterval:1.5];
}

+ (void)breakAfter:(int)thisManyTimes {
    if (timesRemainingBeforeBreak == 0) {
        timesRemainingBeforeBreak = thisManyTimes;
    }
    
    timesRemainingBeforeBreak--;
    
    if (timesRemainingBeforeBreak == 0) {
        PCFPushBreakPoint;
    }
}

+ (void)setLogListener:(PCFPushLogListener)_listener {
    listener = _listener;
}

@end
