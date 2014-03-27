//
//  CFPushDebug.h
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
//  CFPushDebug.h
//
//  Created by Christopher Larsen
//
////////////////////////////////////////////////////////////////////////////////////////////////

/*
 
 CFPushDebug.h is a logging alternative to NSLog
 
 ** Console output will be formatted include File Name, Line Number and Function it was called from. **
 
 
 Compare                          Output
 -------                          ------
 NSLog(@"example");               2013-07-31 13:53:33.573 MyApp[34761:c07] example
 CFPushLog(@"example");        2013-07-31 13:53:33.573 MyApp[34761:c07] -[AppDelegate runAtStartup]<205>: example
 
 
 Installation:
 ============
 
 1. Include CFPushDebug.h and CFPushDebug.m in your project. Import CFPushDebug.h in any files where you wish to use CFPushDebug.
 
 Usage:
 =====
 
 1. Use CFPushLog(@"example"); instead of NSLog(@"example");
 2. Try some of the useful logging commands:
 
 COMMAND                   EFFECT
 =======                   ======
 
 CFPushLog              - Log some text - hidden in release builds
 CFPushLogCritical      - Log some text - visible in release builds
 CFPushTrace            - Log a message. Indicates the current function, line number and path by default
 CFPushError            - Log an error and exit
 CFPushAssert           - Assert the supplied condition is TRUE, if not cite the cause and break program execution
 CFPushBeacon           - Logs a message and pause program execution for a moment so you can see it in the log
 CFPushFlare            - Logs a message ONCE only and pause program execution for a moment. Flares fire one time only.
 CFPushDisableLogging   - Stop logging to the console until XLEnableLogging is called
 CFPushEnableLogging    - Resume logging to the console. By default, logging is enabled.
 CFPushBreakAfter       - Break program execution at this point after it has been called thisManyTimes.
 CFPushBreakPoint       - This inserts a programatic breakpoint.
 
 */

#define CFPushCriticalLog(format,...) [CFPushDebug log:__FILE__    lineNumber:__LINE__ function:__PRETTY_FUNCTION__ thread:[NSThread currentThread] isCritical:YES input:(format), ##__VA_ARGS__]
#define CFPushLog(format,...)         [CFPushDebug log:__FILE__    lineNumber:__LINE__ function:__PRETTY_FUNCTION__ thread:[NSThread currentThread] isCritical:NO input:(format), ##__VA_ARGS__]

#if DEBUG

#define CFPushTrace                   [CFPushDebug trace:__PRETTY_FUNCTION__]
#define CFPushError(format,...)       [CFPushDebug error:__FILE__ lineNumber:__LINE__ function:__PRETTY_FUNCTION__ input:(format), ##__VA_ARGS__]
#define CFPushAssert(eval,format,...) [CFPushDebug assert: eval     output:__FILE__ lineNumber:__LINE__ function:__PRETTY_FUNCTION__ input:(format), ##__VA_ARGS__]
#define CFPushBeacon(format)          [CFPushDebug beacon:(format)]
#define CFPushFlare                   [CFPushDebug flare]
#define CFPushBreakAfter(format)      [CFPushDebug breakAfter:(format)]
#define CFPushEnableLogging           [CFPushDebug disableLogging:NO]
#define CFPushDisableLogging          [CFPushDebug disableLogging:YES]
#define CFPushBreakPoint              kill(getpid(), SIGSTOP)

#else

#define CFPushTrace
#define CFPushError(format,...)
#define CFPushAssert(eval,format,...)
#define CFPushBeacon(format)
#define CFPushFlare
#define CFPushBreakAfter(format)
#define CFPushEnableLogging
#define CFPushDisableLogging
#define CFPushBreakPoint

#endif // if DEBUG

typedef void (^CFPushLogListener)(NSString *context, NSDate *timestamp);

@interface CFPushDebug : NSObject

+ (void)trace:(const char *)stringFunction;
+ (void)log:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction thread:(NSThread*)thread isCritical:(BOOL)isCritical input:(NSString *)input, ...;
+ (void)error:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction input:(NSString *)input, ...;
+ (void)assert:(int)evaluate output:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction input:(NSString *)input, ...;
+ (void)beacon:(NSString *)input, ...;
+ (void)flare;
+ (void)breakAfter:(int)thisManyTimes;
+ (void)disableLogging:(BOOL)loggingDisabled;
+ (void)setLogListener:(CFPushLogListener)listener;

@end
