//
//  NSURLConnection+PCFPushAsync2Sync.h
//  PCFPushSDK
//
//  Created by DX123-XL on 3/13/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
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
