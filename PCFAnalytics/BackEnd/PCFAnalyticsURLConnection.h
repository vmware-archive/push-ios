//
//  PCFAnalyticsURLConnection.h
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import <Foundation/Foundation.h>

NSString *const BACK_END_ANALYTICS_KEY_FIELD;

@interface PCFAnalyticsURLConnection : NSObject

+ (void)syncAnalyicEvents:(NSArray *)events
                  success:(void (^)(NSURLResponse *response, NSData *data))success
                  failure:(void (^)(NSError *error))failure;

@end
