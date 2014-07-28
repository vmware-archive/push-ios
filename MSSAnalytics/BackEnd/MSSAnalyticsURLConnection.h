//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *const BACK_END_ANALYTICS_KEY_FIELD;

@interface MSSAnalyticsURLConnection : NSObject

+ (void)syncAnalyicEvents:(NSArray *)events
                  success:(void (^)(NSURLResponse *response, NSData *data))success
                  failure:(void (^)(NSError *error))failure;

@end
