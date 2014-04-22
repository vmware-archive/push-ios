//
//  NSURLConnection+PCFPushBackEndConnection.m
//  PCFPushSDK
//
//  Created by DX123-XL on 3/4/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "PCFPushErrors.h"
#import "NSURLConnection+PCFPushBackEndConnection.h"
#import "NSObject+PCFPushJsonizable.h"
#import "PCFPushDebug.h"
#import "PCFPushErrorUtil.h"

typedef void (^Handler)(NSURLResponse *response, NSData *data, NSError *connectionError);

static NSString *const BACK_END_ANALYTICS_REQUEST_URL = @"analytics";

@implementation NSURLConnection (PCFPushBackEndConnection)

+ (void)pcf_sendAsynchronousRequest:(NSMutableURLRequest *)request
                            success:(void (^)(NSURLResponse *response, NSData *data))success
                            failure:(void (^)(NSError *error))failure
{
    if (!request || !request.URL) {
        PCFPushLog(@"Required URL request is nil.");
        NSError *error = [NSError errorWithDomain:PCFPushErrorDomain code:PCFPushBackEndUnregistrationFailedRequestStatusCode userInfo:nil];
        if (failure) {
            failure(error);
        }
        return;
    }
    
#warning - Complete GZIP code to compress HTTPBody on POST/PUT
//    if (request.HTTPBody) {
//        [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
//    }
    
    Handler handler = [self completionHandlerWithSuccessBlock:success failureBlock:failure];
    [self sendAsynchronousRequest:request
                            queue:[NSOperationQueue mainQueue]
                completionHandler:handler];
}

#pragma mark - Sync Analytics

+ (void)pcf_syncAnalyicEvents:(NSArray *)events
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
    
    Handler handler = [self completionHandlerWithSuccessBlock:success failureBlock:failure];
    [self sendAsynchronousRequest:request
                            queue:[NSOperationQueue currentQueue]
                completionHandler:handler];
}

+ (NSMutableURLRequest *)syncAnalyicEventsRequestWithDeviceID:(NSString *)backEndDeviceUUID
{
#warning - TODO: Extract analytics to its own library.
//    if (!backEndDeviceUUID) {
//        return nil;
//    }
//    
//    NSURL *analyticsURL = [NSURL URLWithString:BACK_END_ANALYTICS_REQUEST_URL relativeToURL:[self pcf_pushBaseURL]];
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:analyticsURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS];
//    request.HTTPMethod = @"POST";
//    return request;
    return nil;
}

#pragma mark - Utility Methods

+ (BOOL)successfulStatusForHTTPResponse:(NSHTTPURLResponse *)response {
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        return NO;
    }
    return [response statusCode] >= 200 && [response statusCode] < 300;
}

+ (Handler)completionHandlerWithSuccessBlock:(void (^)(NSURLResponse *response, NSData *data))success
                                failureBlock:(void (^)(NSError *error))failure
{
    Handler handler = ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            PCFPushCriticalLog(@"NSURLRequest failed with error: %@ %@", connectionError, connectionError.userInfo);
            if (failure) {
                failure(connectionError);
            }
        } else if (![self successfulStatusForHTTPResponse:(NSHTTPURLResponse *)response]) {
            NSString *description = [NSString stringWithFormat:@"Failed HTTP Status Code: %ld", (long)[(NSHTTPURLResponse *)response statusCode]];
            NSError *error = [PCFPushErrorUtil errorWithCode:PCFPushBackEndRegistrationFailedHTTPStatusCode localizedDescription:description];
            PCFPushCriticalLog(@"NSURLRequest unsuccessful HTTP response code: %@ %@", error, error.userInfo);
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success(response, data);
            }
        }
    };
    return handler;
}

@end
