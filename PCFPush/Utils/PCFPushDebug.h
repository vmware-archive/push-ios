//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//
//  Based on XLDebug by Christopher Larsen, see license below:

#import <Foundation/Foundation.h>

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
 PCFPushLog(@"example");          2013-07-31 13:53:33.573 MyApp[34761:c07] -[AppDelegate runAtStartup]<205>: example
 
 
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

 */

#define PCFPushCriticalLog(format,...) [PCFPushDebug log:__FILE__    lineNumber:__LINE__ function:__PRETTY_FUNCTION__ thread:[NSThread currentThread] isCritical:YES input:(format), ##__VA_ARGS__]
#define PCFPushLog(format,...)         [PCFPushDebug log:__FILE__    lineNumber:__LINE__ function:__PRETTY_FUNCTION__ thread:[NSThread currentThread] isCritical:NO input:(format), ##__VA_ARGS__]

#if DEBUG
#define PCFPushBreakPoint              kill(getpid(), SIGSTOP)
#else
#define PCFPushBreakPoint
#endif

typedef void (^PCFPushLogListener)(NSString *context, NSDate *timestamp);

@interface PCFPushDebug : NSObject

+ (void)log:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction thread:(NSThread*)thread isCritical:(BOOL)isCritical input:(NSString *)input, ...;
+ (void)error:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction input:(NSString *)input, ...;
+ (void)assert:(int)evaluate output:(char *)fileName lineNumber:(int)lineNumber function:(const char *)stringFunction input:(NSString *)input, ...;
+ (void)setLogListener:(PCFPushLogListener)listener;

@end
