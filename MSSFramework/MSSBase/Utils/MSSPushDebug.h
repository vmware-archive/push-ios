//
//  MSSPushDebug.h
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
//  MSSPushDebug.h
//
//  Created by Christopher Larsen
//
////////////////////////////////////////////////////////////////////////////////////////////////

/*
 
 MSSPushDebug.h is a logging alternative to NSLog
 
 ** Console output will be formatted include File Name, Line Number and Function it was called from. **
 
 
 Compare                          Output
 -------                          ------
 NSLog(@"example");               2013-07-31 13:53:33.573 MyApp[34761:c07] example
 MSSPushLog(@"example");        2013-07-31 13:53:33.573 MyApp[34761:c07] -[AppDelegate runAtStartup]<205>: example
 
 
 Installation:
 ============
 
 1. Include MSSPushDebug.h and MSSPushDebug.m in your project. Import MSSPushDebug.h in any files where you wish to use MSSPushDebug.
 
 Usage:
 =====
 
 1. Use MSSPushLog(@"example"); instead of NSLog(@"example");
 2. Try some of the useful logging commands:
 
 COMMAND                   EFFECT
 =======                   ======
 
 MSSPushLog              - Log some text - hidden in release builds
 MSSPushLogCritical      - Log some text - visible in release builds
 MSSPushTrace            - Log a message. Indicates the current function, line number and path by default
 MSSPushError            - Log an error and exit
 MSSPushAssert           - Assert the supplied condition is TRUE, if not cite the cause and break program execution
 MSSPushBeacon           - Logs a message and pause program execution for a moment so you can see it in the log
 MSSPushFlare            - Logs a message ONCE only and pause program execution for a moment. Flares fire one time only.
 MSSPushDisableLogging   - Stop logging to the console until XLEnableLogging is called
 MSSPushEnableLogging    - Resume logging to the console. By default, logging is enabled.
 MSSPushBreakAfter       - Break program execution at this point after it has been called thisManyTimes.
 MSSPushBreakPoint       - This inserts a programatic breakpoint.
 
 */

#define MSSPushCriticalLog(format,...) [MSSPushDebug log:__FILE__    lineNumber:__LINE__ function:__PRETTY_FUNCTION__ thread:[NSThread currentThread] isCritical:YES input:(format), ##__VA_ARGS__]
#define MSSPushLog(format,...)         [MSSPushDebug log:__FILE__    lineNumber:__LINE__ function:__PRETTY_FUNCTION__ thread:[NSThread currentThread] isCritical:NO input:(format), ##__VA_ARGS__]

#if DEBUG

#define MSSPushTrace                   [MSSPushDebug trace:__PRETTY_FUNCTION__]
#define MSSPushError(format,...)       [MSSPushDebug error:__FILE__ lineNumber:__LINE__ function:__PRETTY_FUNCTION__ input:(format), ##__VA_ARGS__]
#define MSSPushAssert(eval,format,...) [MSSPushDebug assert: eval     output:__FILE__ lineNumber:__LINE__ function:__PRETTY_FUNCTION__ input:(format), ##__VA_ARGS__]
#define MSSPushBeacon(format)          [MSSPushDebug beacon:(format)]
#define MSSPushFlare                   [MSSPushDebug flare]
#define MSSPushBreakAfter(format)      [MSSPushDebug breakAfter:(format)]
#define MSSPushEnableLogging           [MSSPushDebug disableLogging:NO]
#define MSSPushDisableLogging          [MSSPushDebug disableLogging:YES]
#define MSSPushBreakPoint              kill(getpid(), SIGSTOP)

#else

#define MSSPushTrace
#define MSSPushError(format,...)
#define MSSPushAssert(eval,format,...)
#define MSSPushBeacon(format)
#define MSSPushFlare
#define MSSPushBreakAfter(format)
#define MSSPushEnableLogging
#define MSSPushDisableLogging
#define MSSPushBreakPoint

#endif // if DEBUG

typedef void (^MSSPushLogListener)(NSString *context, NSDate *timestamp);

@interface MSSPushDebug : NSObject

+ (void)trace:(const char *)stringFunction;
+ (void)log:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction thread:(NSThread*)thread isCritical:(BOOL)isCritical input:(NSString *)input, ...;
+ (void)error:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction input:(NSString *)input, ...;
+ (void)assert:(int)evaluate output:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction input:(NSString *)input, ...;
+ (void)beacon:(NSString *)input, ...;
+ (void)flare;
+ (void)breakAfter:(int)thisManyTimes;
+ (void)disableLogging:(BOOL)loggingDisabled;
+ (void)setLogListener:(MSSPushLogListener)listener;

@end
