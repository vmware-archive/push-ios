//
//  PCFAnalyticsURLConnection.m
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import <UIKit/UIKit.h>

#import "PCFAnalyticsURLConnection.h"
#import "NSURLConnection+PCFBackEndConnection.h"
#import "NSObject+PCFJsonizable.h"
#import "PCFPushDebug.h"
#import "PCFParameters.h"
#import "PCFClient.h"

static NSString *const BACK_END_ANALYTICS_REQUEST_URL = @"analytics";
static NSTimeInterval kAnalyticsSyncTimeout = 60.0;

NSString *const BACK_END_ANALYTICS_KEY_FIELD = @"analyticsKey";

@implementation PCFAnalyticsURLConnection

#pragma mark - Sync Analytics

+ (void)syncAnalyicEvents:(NSArray *)events
                  success:(void (^)(NSURLResponse *response, NSData *data))success
                  failure:(void (^)(NSError *error))failure
{
    if (!events) {
        PCFPushCriticalLog(@"Analytic events is nil. Unable to sync analytics with server.");
        return;
    }
    
    if (events.count == 0) {
        PCFPushCriticalLog(@"Analytic events is empty. Unable to sync analytics with server.");
        return;
    }
    
    NSString *analyticsKey = [self analyticsKey];
    if (!analyticsKey) {
        PCFPushCriticalLog(@"Analytics key is nil or not set correctly. Unable to sync analytics with server.");
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
    [NSURLConnection pcf_sendAsynchronousRequest:request
                                           queue:[NSOperationQueue currentQueue]
                                         success:(void (^)(NSURLResponse *response, NSData *data))success
                                         failure:(void (^)(NSError *error))failure];
}

+ (NSData *)createHTTPBodyForEvents:(NSArray *)events
{
    NSDictionary *payloadDictionary = @{
                                        @"device_id": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                        @"events" : events,
                                        };
    NSError *error;
    NSData *bodyData = [payloadDictionary pcf_toJSONData:&error];
    if (!bodyData) {
        PCFPushCriticalLog(@"Error while converting analytic event to JSON: %@ %@", error, error.userInfo);
        return nil;
    }
    
    return bodyData;
}

+ (NSURL *)analyticsBaseURL
{
    PCFParameters *params = [[PCFClient shared] registrationParameters];
    if (!params || !params.analyticsAPIURL) {
        PCFPushLog(@"PCFAnalyticsURLConnection baseURL is nil");
        return nil;
    }
    return [NSURL URLWithString:params.analyticsAPIURL];
}

+ (NSString *)analyticsKey
{
    PCFParameters *params = [[PCFClient shared] registrationParameters];
    if (!params || !params.analyticsKey) {
        PCFPushLog(@"PCFAnalyticsURLConnection analytics key is nil");
        return nil;
    }
    return params.analyticsKey;
}

@end
