//
//  PMSSAnalyticsURLConnection.m
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import <UIKit/UIKit.h>

#import "PMSSAnalyticsURLConnection.h"
#import "NSURLConnection+PMSSBackEndConnection.h"
#import "NSObject+PMSSJsonizable.h"
#import "PMSSPushDebug.h"
#import "PMSSParameters.h"
#import "PMSSClient.h"

static NSString *const BACK_END_ANALYTICS_REQUEST_URL = @"analytics";
static NSTimeInterval kAnalyticsSyncTimeout = 60.0;

NSString *const BACK_END_ANALYTICS_KEY_FIELD = @"analyticsKey";

@implementation PMSSAnalyticsURLConnection

#pragma mark - Sync Analytics

+ (void)syncAnalyicEvents:(NSArray *)events
                  success:(void (^)(NSURLResponse *response, NSData *data))success
                  failure:(void (^)(NSError *error))failure
{
    if (!events) {
        PMSSPushCriticalLog(@"Analytic events is nil. Unable to sync analytics with server.");
        return;
    }
    
    if (events.count == 0) {
        PMSSPushCriticalLog(@"Analytic events is empty. Unable to sync analytics with server.");
        return;
    }
    
    NSString *analyticsKey = [self analyticsKey];
    if (!analyticsKey) {
        PMSSPushCriticalLog(@"Analytics key is nil or not set correctly. Unable to sync analytics with server.");
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
    [NSURLConnection pmss_sendAsynchronousRequest:request
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
    NSData *bodyData = [payloadDictionary pmss_toJSONData:&error];
    if (!bodyData) {
        PMSSPushCriticalLog(@"Error while converting analytic event to JSON: %@ %@", error, error.userInfo);
        return nil;
    }
    
    return bodyData;
}

+ (NSURL *)analyticsBaseURL
{
    PMSSParameters *params = [[PMSSClient shared] registrationParameters];
    if (!params || !params.analyticsAPIURL) {
        PMSSPushLog(@"PMSSAnalyticsURLConnection baseURL is nil");
        return nil;
    }
    return [NSURL URLWithString:params.analyticsAPIURL];
}

+ (NSString *)analyticsKey
{
    PMSSParameters *params = [[PMSSClient shared] registrationParameters];
    if (!params || !params.analyticsKey) {
        PMSSPushLog(@"PMSSAnalyticsURLConnection analytics key is nil");
        return nil;
    }
    return params.analyticsKey;
}

@end
