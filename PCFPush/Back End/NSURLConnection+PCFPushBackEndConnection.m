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

@implementation NSURLConnection (PCFPushBackEndConnection)

+ (void)pcf_sendAsynchronousRequest:(NSURLRequest *)request
                            success:(void (^)(NSURLResponse *response, NSData *data))success
                            failure:(void (^)(NSError *error))failure
{
    [self pcf_sendAsynchronousRequest:request
                                queue:[NSOperationQueue mainQueue]
                              success:success
                              failure:failure];
}

+ (void)pcf_sendAsynchronousRequest:(NSURLRequest *)request
                              queue:(NSOperationQueue *)queue
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
