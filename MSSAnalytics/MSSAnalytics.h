//
//  MSSAnalytics.h
//  
//
//  Created by DX123-XL on 2014-04-01.
//
//

#import <Foundation/Foundation.h>
#import "MSSSDK+Analytics.h"

@interface MSSAnalytics : NSObject

+ (void)logEvent:(NSString *)eventName;
+ (void)logEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters;
+ (void)logError:(NSString *)errorID message:(NSString *)message exception:(NSException *)exception;
+ (void)logError:(NSString *)errorID message:(NSString *)message error:(NSError *)error;

@end
