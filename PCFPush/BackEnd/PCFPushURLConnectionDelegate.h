//
// Created by DX173-XL on 15-06-15.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCFPush.h"

@interface PCFPushURLConnectionDelegate : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

+ (void) setAuthenticationCallback:(PCFPushAuthenticationCallback)authenticationCallback;

- (instancetype)initWithRequest:(NSURLRequest *)request
                          queue:(NSOperationQueue *)queue
              completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;

@end