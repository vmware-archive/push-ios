//
//  PMSSPushDebug.h
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
//  PMSSPushDebug.h
//
//  Created by Christopher Larsen
//
////////////////////////////////////////////////////////////////////////////////////////////////

/*
 
 PMSSPushDebug.h is a logging alternative to NSLog
 
 ** Console output will be formatted include File Name, Line Number and Function it was called from. **
 
 
 Compare                          Output
 -------                          ------
 NSLog(@"example");               2013-07-31 13:53:33.573 MyApp[34761:c07] example
 PMSSPushLog(@"example");        2013-07-31 13:53:33.573 MyApp[34761:c07] -[AppDelegate runAtStartup]<205>: example
 
 
 Installation:
 ============
 
 1. Include PMSSPushDebug.h and PMSSPushDebug.m in your project. Import PMSSPushDebug.h in any files where you wish to use PMSSPushDebug.
 
 Usage:
 =====
 
 1. Use PMSSPushLog(@"example"); instead of NSLog(@"example");
 2. Try some of the useful logging commands:
 
 COMMAND                   EFFECT
 =======                   ======
 
 PMSSPushLog              - Log some text - hidden in release builds
 PMSSPushLogCritical      - Log some text - visible in release builds
 PMSSPushTrace            - Log a message. Indicates the current function, line number and path by default
 PMSSPushError            - Log an error and exit
 PMSSPushAssert           - Assert the supplied condition is TRUE, if not cite the cause and break program execution
 PMSSPushBeacon           - Logs a message and pause program execution for a moment so you can see it in the log
 PMSSPushFlare            - Logs a message ONCE only and pause program execution for a moment. Flares fire one time only.
 PMSSPushDisableLogging   - Stop logging to the console until XLEnableLogging is called
 PMSSPushEnableLogging    - Resume logging to the console. By default, logging is enabled.
 PMSSPushBreakAfter       - Break program execution at this point after it has been called thisManyTimes.
 PMSSPushBreakPoint       - This inserts a programatic breakpoint.
 
 */

#define PMSSPushCriticalLog(format,...) [PMSSPushDebug log:__FILE__    lineNumber:__LINE__ function:__PRETTY_FUNCTION__ thread:[NSThread currentThread] isCritical:YES input:(format), ##__VA_ARGS__]
#define PMSSPushLog(format,...)         [PMSSPushDebug log:__FILE__    lineNumber:__LINE__ function:__PRETTY_FUNCTION__ thread:[NSThread currentThread] isCritical:NO input:(format), ##__VA_ARGS__]

#if DEBUG

#define PMSSPushTrace                   [PMSSPushDebug trace:__PRETTY_FUNCTION__]
#define PMSSPushError(format,...)       [PMSSPushDebug error:__FILE__ lineNumber:__LINE__ function:__PRETTY_FUNCTION__ input:(format), ##__VA_ARGS__]
#define PMSSPushAssert(eval,format,...) [PMSSPushDebug assert: eval     output:__FILE__ lineNumber:__LINE__ function:__PRETTY_FUNCTION__ input:(format), ##__VA_ARGS__]
#define PMSSPushBeacon(format)          [PMSSPushDebug beacon:(format)]
#define PMSSPushFlare                   [PMSSPushDebug flare]
#define PMSSPushBreakAfter(format)      [PMSSPushDebug breakAfter:(format)]
#define PMSSPushEnableLogging           [PMSSPushDebug disableLogging:NO]
#define PMSSPushDisableLogging          [PMSSPushDebug disableLogging:YES]
#define PMSSPushBreakPoint              kill(getpid(), SIGSTOP)

#else

#define PMSSPushTrace
#define PMSSPushError(format,...)
#define PMSSPushAssert(eval,format,...)
#define PMSSPushBeacon(format)
#define PMSSPushFlare
#define PMSSPushBreakAfter(format)
#define PMSSPushEnableLogging
#define PMSSPushDisableLogging
#define PMSSPushBreakPoint

#endif // if DEBUG

typedef void (^PMSSPushLogListener)(NSString *context, NSDate *timestamp);

@interface PMSSPushDebug : NSObject

+ (void)trace:(const char *)stringFunction;
+ (void)log:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction thread:(NSThread*)thread isCritical:(BOOL)isCritical input:(NSString *)input, ...;
+ (void)error:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction input:(NSString *)input, ...;
+ (void)assert:(int)evaluate output:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction input:(NSString *)input, ...;
+ (void)beacon:(NSString *)input, ...;
+ (void)flare;
+ (void)breakAfter:(int)thisManyTimes;
+ (void)disableLogging:(BOOL)loggingDisabled;
+ (void)setLogListener:(PMSSPushLogListener)listener;

@end
