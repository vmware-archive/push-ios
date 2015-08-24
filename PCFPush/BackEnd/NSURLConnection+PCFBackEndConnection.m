//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushErrors.h"
#import "NSURLConnection+PCFBackEndConnection.h"
#import "PCFPushDebug.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushURLConnectionDelegate.h"

static BOOL isSuccessfulStatusForHTTPResponse(NSHTTPURLResponse *response)
{
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        return NO;
    }
    return [response statusCode] >= 200 && [response statusCode] < 300;
}

static BOOL isAuthError(NSError *error)
{
    if (!error) {
        return NO;
    }
    return ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == NSURLErrorUserCancelledAuthentication || error.code == NSURLErrorUserAuthenticationRequired));
}

@implementation NSURLConnection (PCFBackEndConnection)

+ (void)pcfPushSendAsynchronousRequest:(NSURLRequest *)request
                               success:(void (^)(NSURLResponse *response, NSData *data))success
                               failure:(void (^)(NSURLResponse *response, NSError *error))failure
{
    [self pcfPushSendAsynchronousRequest:request
                                   queue:[NSOperationQueue mainQueue]
                                 success:success
                                 failure:failure];
}

+ (void)pcfPushSendAsynchronousRequest:(NSURLRequest *)request
                                 queue:(NSOperationQueue *)queue
                               success:(void (^)(NSURLResponse *response, NSData *data))success
                               failure:(void (^)(NSURLResponse *response, NSError *error))failure
{
    if (!request || !request.URL) {
        PCFPushLog(@"Required URL request is nil.");
        NSError *error = [NSError errorWithDomain:PCFPushErrorDomain code:PCFPushBackEndInvalidRequestStatusCode userInfo:nil];
        if (failure) {
            failure(nil, error);
        }
        return;
    }

    CompletionHandler handler = [self completionHandlerWithSuccessBlock:success failureBlock:failure];
    [self pcfPushSendAsynchronousRequestWrapper:request
                                          queue:queue
                              completionHandler:handler];
}

+ (void)pcfPushSendAsynchronousRequestWrapper:(NSURLRequest *)request
                                        queue:(NSOperationQueue *)queue
                            completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    PCFPushURLConnectionDelegate *delegate = [[PCFPushURLConnectionDelegate alloc] initWithRequest:request queue:queue completionHandler:handler];
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:delegate];
}

#pragma mark - Utility Methods

+ (CompletionHandler)completionHandlerWithSuccessBlock:(void (^)(NSURLResponse *, NSData *))success
                                          failureBlock:(void (^)(NSURLResponse *, NSError *))failure
{
    CompletionHandler handler = ^(NSURLResponse *response, NSData *data, NSError *connectionError) {

        if (response == nil && connectionError == nil) {

            PCFPushCriticalLog(@"NSURLRequest empty server error and response.");
            if (failure) {
                NSString *description = @"Empty server response and error";
                NSError *error = [PCFPushErrorUtil errorWithCode:PCFPushBackEndConnectionEmptyErrorAndResponse localizedDescription:description];
                failure(response, error);
            }

        } else if (isAuthError(connectionError)) {

            PCFPushCriticalLog(@"NSURLRequest failed with authentication error.");
            if (failure) {
                NSError *authError = [PCFPushErrorUtil errorWithCode:PCFPushBackEndAuthenticationError localizedDescription:@"Authentication error while communicating with the back-end server.  Check your platform uuid and secret parameters."];
                failure(response, authError);
            }

        } else if (connectionError) {
            PCFPushCriticalLog(@"NSURLRequest failed with error: %@ %@", connectionError, connectionError.userInfo);
            if (failure) {
                failure(response, connectionError);
            }

        } else if (!isSuccessfulStatusForHTTPResponse((NSHTTPURLResponse *)response)) {

            NSString *description = [NSString stringWithFormat:@"Failed HTTP Status Code: %ld", (long)[(NSHTTPURLResponse *)response statusCode]];
            NSError *error = [PCFPushErrorUtil errorWithCode:PCFPushBackEndConnectionFailedHTTPStatusCode localizedDescription:description];
            PCFPushCriticalLog(@"NSURLRequest unsuccessful HTTP response code: %@ %@", error, error.userInfo);
            if (failure) {
                failure(response, error);
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
