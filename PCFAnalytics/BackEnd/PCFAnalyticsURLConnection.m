//
//  PCFAnalyticsURLConnection.m
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import "PCFAnalyticsURLConnection.h"
#import "NSURLConnection+PCFPushBackEndConnection.h"
#import "NSObject+PCFPushJsonizable.h"
#import "PCFPushDebug.h"
#import "PCFParameters.h"
#import "PCFClient.h"

static NSString *const BACK_END_ANALYTICS_REQUEST_URL = @"analytics";
static NSTimeInterval kAnalyticsSyncTimeout = 60.0;

@implementation PCFAnalyticsURLConnection

#pragma mark - Sync Analytics

+ (void)syncAnalyicEvents:(NSArray *)events
              forDeviceID:(NSString *)deviceID
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
    
    NSMutableURLRequest *request = [self syncAnalyicEventsRequestWithDeviceID:deviceID];
    NSError *error;
    NSData *bodyData = [events toJSONData:&error];
    if (error) {
        PCFPushCriticalLog(@"Error while converting analytic event to JSON: %@ %@", error, error.userInfo);
        return;
    }
    request.HTTPBody = bodyData;
    [NSURLConnection pcf_sendAsynchronousRequest:request
                                           queue:[NSOperationQueue currentQueue]
                                         success:(void (^)(NSURLResponse *response, NSData *data))success
                                         failure:(void (^)(NSError *error))failure];
}

+ (NSMutableURLRequest *)syncAnalyicEventsRequestWithDeviceID:(NSString *)backEndDeviceUUID
{
#warning - TODO: Extract analytics to its own library.
    if (!backEndDeviceUUID) {
        return nil;
    }

    NSURL *analyticsURL = [NSURL URLWithString:BACK_END_ANALYTICS_REQUEST_URL relativeToURL:[self analyticsBaseURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:analyticsURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kAnalyticsSyncTimeout];
    request.HTTPMethod = @"POST";
    return request;
}

+ (NSURL *)analyticsBaseURL
{
    PCFParameters *params = [[PCFClient shared] registrationParameters];
    if (!params || !params.analyticsAPIURL) {
        PCFPushLog(@"PCFPushURLConnection baseURL is nil");
        return nil;
    }
    return [NSURL URLWithString:params.analyticsAPIURL];
}


@end
