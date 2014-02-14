//
//  OmniaPushDebug.h
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
//  OmniaPushDebug.h
//
//  Created by Christopher Larsen
//
////////////////////////////////////////////////////////////////////////////////////////////////

/*
 
 OmniaPushDebug.h is a logging alternative to NSLog
 
 ** Console output will be formatted include File Name, Line Number and Function it was called from. **
 
 
 Compare                          Output
 -------                          ------
 NSLog(@"example");               2013-07-31 13:53:33.573 MyApp[34761:c07] example
 OmniaPushLog(@"example");        2013-07-31 13:53:33.573 MyApp[34761:c07] -[AppDelegate runAtStartup]<205>: example
 
 
 Installation:
 ============
 
 1. Include OmniaPushDebug.h and OmniaPushDebug.m in your project. Import OmniaPushDebug.h in any files where you wish to use OmniaPushDebug.
 
 Usage:
 =====
 
 1. Use OmniaPushLog(@"example"); instead of NSLog(@"example");
 2. Try some of the useful logging commands:
 
 COMMAND                   EFFECT
 =======                   ======
 
 OmniaPushLog              - Log some text - hidden in release builds
 OmniaPushLogCritical      - Log some text - visible in release builds
 OmniaPushTrace            - Log a message. Indicates the current function, line number and path by default
 OmniaPushError            - Log an error and exit
 OmniaPushAssert           - Assert the supplied condition is TRUE, if not cite the cause and break program execution
 OmniaPushBeacon           - Logs a message and pause program execution for a moment so you can see it in the log
 OmniaPushFlare            - Logs a message ONCE only and pause program execution for a moment. Flares fire one time only.
 OmniaPushDisableLogging   - Stop logging to the console until XLEnableLogging is called
 OmniaPushEnableLogging    - Resume logging to the console. By default, logging is enabled.
 OmniaPushBreakAfter       - Break program execution at this point after it has been called thisManyTimes.
 OmniaPushBreakPoint       - This inserts a programatic breakpoint.
 
 */

#define OmniaPushCriticalLog(format,...) [OmniaPushDebug log:__FILE__    lineNumber:__LINE__ function:__PRETTY_FUNCTION__ thread:[NSThread currentThread] input:(format), ##__VA_ARGS__]
#define OmniaPushLog(format,...)         [OmniaPushDebug log:__FILE__    lineNumber:__LINE__ function:__PRETTY_FUNCTION__ thread:[NSThread currentThread] input:(format), ##__VA_ARGS__]

#if DEBUG

#define OmniaPushTrace                   [OmniaPushDebug trace:__PRETTY_FUNCTION__]
#define OmniaPushError(format,...)       [OmniaPushDebug error:__FILE__ lineNumber:__LINE__ function:__PRETTY_FUNCTION__ input:(format), ##__VA_ARGS__]
#define OmniaPushAssert(eval,format,...) [OmniaPushDebug assert: eval     output:__FILE__ lineNumber:__LINE__ function:__PRETTY_FUNCTION__ input:(format), ##__VA_ARGS__]
#define OmniaPushBeacon(format)          [OmniaPushDebug beacon:(format)]
#define OmniaPushFlare                   [OmniaPushDebug flare]
#define OmniaPushBreakAfter(format)      [OmniaPushDebug breakAfter:(format)]
#define OmniaPushEnableLogging           [OmniaPushDebug disableLogging:NO]
#define OmniaPushDisableLogging          [OmniaPushDebug disableLogging:YES]
#define OmniaPushBreakPoint              kill(getpid(), SIGSTOP)

#else

#define OmniaPushTrace
#define OmniaPushError(format,...)
#define OmniaPushAssert(eval,format,...)
#define OmniaPushBeacon(format)
#define OmniaPushFlare
#define OmniaPushBreakAfter(format)
#define OmniaPushEnableLogging
#define OmniaPushDisableLogging
#define OmniaPushBreakPoint

#endif // if DEBUG

typedef void (^OmniaPushLogListener)(NSString *context, NSDate *timestamp);

@interface OmniaPushDebug : NSObject

+ (void)trace:(const char *)stringFunction;
+ (void)log:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction thread:(NSThread*)thread input:(NSString *)input, ...;
+ (void)error:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction input:(NSString *)input, ...;
+ (void)assert:(int)evaluate output:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction input:(NSString *)input, ...;
+ (void)beacon:(NSString *)input, ...;
+ (void)flare;
+ (void)breakAfter:(int)thisManyTimes;
+ (void)disableLogging:(BOOL)loggingDisabled;
+ (void)setLogListener:(OmniaPushLogListener)listener;

@end