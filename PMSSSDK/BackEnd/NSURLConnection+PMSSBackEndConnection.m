//
//  NSURLConnection+PMSSPushBackEndConnection.m
//  PMSSPushSDK
//
//  Created by DX123-XL on 3/4/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "PMSSPushErrors.h"
#import "NSURLConnection+PMSSBackEndConnection.h"
#import "NSObject+PMSSJsonizable.h"
#import "PMSSPushDebug.h"
#import "PMSSPushErrorUtil.h"

@implementation NSURLConnection (PMSSBackEndConnection)

+ (void)pmss_sendAsynchronousRequest:(NSURLRequest *)request
                            success:(void (^)(NSURLResponse *response, NSData *data))success
                            failure:(void (^)(NSError *error))failure
{
    [self pmss_sendAsynchronousRequest:request
                                queue:[NSOperationQueue mainQueue]
                              success:success
                              failure:failure];
}

+ (void)pmss_sendAsynchronousRequest:(NSURLRequest *)request
                              queue:(NSOperationQueue *)queue
                            success:(void (^)(NSURLResponse *response, NSData *data))success
                            failure:(void (^)(NSError *error))failure
{
    if (!request || !request.URL) {
        PMSSPushLog(@"Required URL request is nil.");
        NSError *error = [NSError errorWithDomain:PMSSPushErrorDomain code:PMSSPushBackEndUnregistrationFailedRequestStatusCode userInfo:nil];
        if (failure) {
            failure(error);
        }
        return;
    }
    
#warning - Complete GZIP code to compress HTTPBody on POST/PUT
    //    if (request.HTTPBody) {
    //        [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    //    }
    
    CompletionHandler handler = [self completionHandlerWithSuccessBlock:success failureBlock:failure];
    [self sendAsynchronousRequest:request
                            queue:queue
                completionHandler:handler];
}

#pragma mark - Utility Methods

+ (BOOL)successfulStatusForHTTPResponse:(NSHTTPURLResponse *)response {
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        return NO;
    }
    return [response statusCode] >= 200 && [response statusCode] < 300;
}

+ (CompletionHandler)completionHandlerWithSuccessBlock:(void (^)(NSURLResponse *response, NSData *data))success
                                failureBlock:(void (^)(NSError *error))failure
{
    CompletionHandler handler = ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            PMSSPushCriticalLog(@"NSURLRequest failed with error: %@ %@", connectionError, connectionError.userInfo);
            if (failure) {
                failure(connectionError);
            }
        } else if (![self successfulStatusForHTTPResponse:(NSHTTPURLResponse *)response]) {
            NSString *description = [NSString stringWithFormat:@"Failed HTTP Status Code: %ld", (long)[(NSHTTPURLResponse *)response statusCode]];
            NSError *error = [PMSSPushErrorUtil errorWithCode:PMSSPushBackEndRegistrationFailedHTTPStatusCode localizedDescription:description];
            PMSSPushCriticalLog(@"NSURLRequest unsuccessful HTTP response code: %@ %@", error, error.userInfo);
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
