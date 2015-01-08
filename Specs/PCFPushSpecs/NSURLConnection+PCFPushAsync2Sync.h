//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLConnection (PCFPushAsync2Sync)

+ (void) successfulRequest:(NSURLRequest *)request
                     queue:(NSOperationQueue *)queue
         completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) handler;

+ (void) failedRequestRequest:(NSURLRequest *)request
                         queue:(NSOperationQueue *)queue
             completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError)) handler;

+ (void) HTTPErrorResponseRequest:(NSURLRequest *)request
                            queue:(NSOperationQueue *)queue
                completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError)) handler;

+ (void) emptyDataResponseRequest:(NSURLRequest *)request
                            queue:(NSOperationQueue *)queue
                completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError)) handler;

+ (void) nilDataResponseRequest:(NSURLRequest *)request
                          queue:(NSOperationQueue *)queue
              completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError)) handler;

+ (void) zeroLengthDataResponseRequest:(NSURLRequest *)request
                                 queue:(NSOperationQueue *)queue
                     completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError)) handler;

+ (void) unparseableDataResponseRequest:(NSURLRequest *)request
                                 queue:(NSOperationQueue *)queue
                     completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) handler;

+ (void) missingUUIDResponseRequest:(NSURLRequest *)request
                                  queue:(NSOperationQueue *)queue
                      completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError)) handler;

@end
