//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MSSAnalyticsURLConnection.h"
#import "NSURLConnection+MSSBackEndConnection.h"
#import "NSObject+MSSJsonizable.h"
#import "MSSPushDebug.h"
#import "MSSParameters.h"
#import "MSSClient.h"

static NSString *const BACK_END_ANALYTICS_REQUEST_URL = @"analytics";
static NSTimeInterval kAnalyticsSyncTimeout = 60.0;

NSString *const BACK_END_ANALYTICS_KEY_FIELD = @"analyticsKey";

@implementation MSSAnalyticsURLConnection

#pragma mark - Sync Analytics

+ (void)syncAnalyicEvents:(NSArray *)events
                  success:(void (^)(NSURLResponse *response, NSData *data))success
                  failure:(void (^)(NSError *error))failure
{
    if (!events) {
        MSSPushCriticalLog(@"Analytic events is nil. Unable to sync analytics with server.");
        return;
    }
    
    if (events.count == 0) {
        MSSPushCriticalLog(@"Analytic events is empty. Unable to sync analytics with server.");
        return;
    }
    
    NSString *analyticsKey = [self analyticsKey];
    if (!analyticsKey) {
        MSSPushCriticalLog(@"Analytics key is nil or not set correctly. Unable to sync analytics with server.");
        return;
    }
    
    NSURL *analyticsURL = [NSURL URLWithString:BACK_END_ANALYTICS_REQUEST_URL relativeToURL:[self analyticsBaseURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:analyticsURL
                                                                cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                            timeoutInterval:kAnalyticsSyncTimeout];
    request.HTTPMethod = @"POST";
    [request setValue:analyticsKey forHTTPHeaderField:BACK_END_ANALYTICS_KEY_FIELD];

    NSData *bodyData = [self createHTTPBodyForEvents:events];
    
    request.HTTPBody = bodyData;
    [NSURLConnection mss_sendAsynchronousRequest:request
                                           queue:[NSOperationQueue currentQueue]
                                         success:(void (^)(NSURLResponse *response, NSData *data))success
                                         failure:(void (^)(NSError *error))failure];
}

+ (NSData *)createHTTPBodyForEvents:(NSArray *)events
{
    NSString *vendorID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSDictionary *payloadDictionary = @{
                                        @"device_id": vendorID ?: @"NA",
                                        @"events" : events,
                                        };
    NSError *error;
    NSData *bodyData = [payloadDictionary mss_toJSONData:&error];
    if (!bodyData) {
        MSSPushCriticalLog(@"Error while converting analytic event to JSON: %@ %@", error, error.userInfo);
        return nil;
    }
    
    return bodyData;
}

+ (NSURL *)analyticsBaseURL
{
    MSSParameters *params = [[MSSClient shared] registrationParameters];
    if (!params || !params.analyticsAPIURL) {
        MSSPushLog(@"MSSAnalyticsURLConnection baseURL is nil");
        return nil;
    }
    return [NSURL URLWithString:params.analyticsAPIURL];
}

+ (NSString *)analyticsKey
{
    MSSParameters *params = [[MSSClient shared] registrationParameters];
    if (!params || !params.analyticsKey) {
        MSSPushLog(@"MSSAnalyticsURLConnection analytics key is nil");
        return nil;
    }
    return params.analyticsKey;
}

@end
