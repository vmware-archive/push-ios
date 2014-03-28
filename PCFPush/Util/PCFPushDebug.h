//
//  PCFPushDebug.h
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
//  PCFPushDebug.h
//
//  Created by Christopher Larsen
//
////////////////////////////////////////////////////////////////////////////////////////////////

/*
 
 PCFPushDebug.h is a logging alternative to NSLog
 
 ** Console output will be formatted include File Name, Line Number and Function it was called from. **
 
 
 Compare                          Output
 -------                          ------
 NSLog(@"example");               2013-07-31 13:53:33.573 MyApp[34761:c07] example
 PCFPushLog(@"example");        2013-07-31 13:53:33.573 MyApp[34761:c07] -[AppDelegate runAtStartup]<205>: example
 
 
 Installation:
 ============
 
 1. Include PCFPushDebug.h and PCFPushDebug.m in your project. Import PCFPushDebug.h in any files where you wish to use PCFPushDebug.
 
 Usage:
 =====
 
 1. Use PCFPushLog(@"example"); instead of NSLog(@"example");
 2. Try some of the useful logging commands:
 
 COMMAND                   EFFECT
 =======                   ======
 
 PCFPushLog              - Log some text - hidden in release builds
 PCFPushLogCritical      - Log some text - visible in release builds
 PCFPushTrace            - Log a message. Indicates the current function, line number and path by default
 PCFPushError            - Log an error and exit
 PCFPushAssert           - Assert the supplied condition is TRUE, if not cite the cause and break program execution
 PCFPushBeacon           - Logs a message and pause program execution for a moment so you can see it in the log
 PCFPushFlare            - Logs a message ONCE only and pause program execution for a moment. Flares fire one time only.
 PCFPushDisableLogging   - Stop logging to the console until XLEnableLogging is called
 PCFPushEnableLogging    - Resume logging to the console. By default, logging is enabled.
 PCFPushBreakAfter       - Break program execution at this point after it has been called thisManyTimes.
 PCFPushBreakPoint       - This inserts a programatic breakpoint.
 
 */

#define PCFPushCriticalLog(format,...) [PCFPushDebug log:__FILE__    lineNumber:__LINE__ function:__PRETTY_FUNCTION__ thread:[NSThread currentThread] isCritical:YES input:(format), ##__VA_ARGS__]
#define PCFPushLog(format,...)         [PCFPushDebug log:__FILE__    lineNumber:__LINE__ function:__PRETTY_FUNCTION__ thread:[NSThread currentThread] isCritical:NO input:(format), ##__VA_ARGS__]

#if DEBUG

#define PCFPushTrace                   [PCFPushDebug trace:__PRETTY_FUNCTION__]
#define PCFPushError(format,...)       [PCFPushDebug error:__FILE__ lineNumber:__LINE__ function:__PRETTY_FUNCTION__ input:(format), ##__VA_ARGS__]
#define PCFPushAssert(eval,format,...) [PCFPushDebug assert: eval     output:__FILE__ lineNumber:__LINE__ function:__PRETTY_FUNCTION__ input:(format), ##__VA_ARGS__]
#define PCFPushBeacon(format)          [PCFPushDebug beacon:(format)]
#define PCFPushFlare                   [PCFPushDebug flare]
#define PCFPushBreakAfter(format)      [PCFPushDebug breakAfter:(format)]
#define PCFPushEnableLogging           [PCFPushDebug disableLogging:NO]
#define PCFPushDisableLogging          [PCFPushDebug disableLogging:YES]
#define PCFPushBreakPoint              kill(getpid(), SIGSTOP)

#else

#define PCFPushTrace
#define PCFPushError(format,...)
#define PCFPushAssert(eval,format,...)
#define PCFPushBeacon(format)
#define PCFPushFlare
#define PCFPushBreakAfter(format)
#define PCFPushEnableLogging
#define PCFPushDisableLogging
#define PCFPushBreakPoint

#endif // if DEBUG

typedef void (^PCFPushLogListener)(NSString *context, NSDate *timestamp);

@interface PCFPushDebug : NSObject

+ (void)trace:(const char *)stringFunction;
+ (void)log:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction thread:(NSThread*)thread isCritical:(BOOL)isCritical input:(NSString *)input, ...;
+ (void)error:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction input:(NSString *)input, ...;
+ (void)assert:(int)evaluate output:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction input:(NSString *)input, ...;
+ (void)beacon:(NSString *)input, ...;
+ (void)flare;
+ (void)breakAfter:(int)thisManyTimes;
+ (void)disableLogging:(BOOL)loggingDisabled;
+ (void)setLogListener:(PCFPushLogListener)listener;

@end
