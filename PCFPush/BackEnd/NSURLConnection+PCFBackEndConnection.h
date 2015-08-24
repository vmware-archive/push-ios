//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CompletionHandler)(NSURLResponse *response, NSData *data, NSError *connectionError);

@interface NSURLConnection (PCFBackEndConnection)

+ (void)pcfPushSendAsynchronousRequest:(NSURLRequest *)request
                               success:(void (^)(NSURLResponse *, NSData *))success
                               failure:(void (^)(NSURLResponse *, NSError *))failure;

+ (void)pcfPushSendAsynchronousRequest:(NSURLRequest *)request
                                 queue:(NSOperationQueue *)queue
                               success:(void (^)(NSURLResponse *, NSData *))success
                               failure:(void (^)(NSURLResponse *, NSError *))failure;

+ (void)pcfPushSendAsynchronousRequestWrapper:(NSURLRequest *)request
                                        queue:(NSOperationQueue *)queue
                            completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;

@end
