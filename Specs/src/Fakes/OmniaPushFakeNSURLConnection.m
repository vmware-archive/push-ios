//
//  OmniaPushFakeNSURLConnection.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushFakeNSURLConnection.h"

@interface OmniaPushFakeNSURLConnection ()

@property (nonatomic) BOOL shouldBeSuccessful;
@property (nonatomic) NSError *error;
@property (nonatomic) NSURLResponse *response;
@property (nonatomic) NSArray *chunks;
@property (nonatomic) id<NSURLConnectionDelegate> delegate;

@end

@implementation OmniaPushFakeNSURLConnection

- (id)initWithRequest:(NSURLRequest*)request
             delegate:(id<NSURLConnectionDelegate>)delegate
     startImmediately:(BOOL)startImmediately
{
    self = [super initWithRequest:request delegate:delegate startImmediately:startImmediately];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

- (void) setupForFailureWithError:(NSError*)error
{
    self.shouldBeSuccessful = NO;
    self.error = error;
}

- (void) setupForSuccessWithResponse:(NSURLResponse*)response withDataInChunks:(NSArray*)chunks
{
    self.shouldBeSuccessful = YES;
    self.response = response;
    self.chunks = chunks;
}


- (void) start
{
    // TODO - support ASYNC request in order to test timeouts
    if (self.shouldBeSuccessful) {
        
        SEL selConnectionDidReceiveResponse = sel_registerName("connection:didReceiveResponse:");
        SEL selConnectionDidReceiveData = sel_registerName("connection:didReceiveData:");
        SEL selConnectionDidFinishLoading = sel_registerName("connectionDidFinishLoading:");
        
        if ([self.delegate respondsToSelector:selConnectionDidReceiveResponse]) {
            
            [(id<NSURLConnectionDataDelegate>)(self.delegate) connection:self didReceiveResponse:self.response];
            
            if ([self.delegate respondsToSelector:selConnectionDidReceiveData]) {
                if (self.chunks != nil) {
                    if (self.chunks.count > 0) {
                        for (id chunk in self.chunks) {
                            NSData *data = nil;
                            if ([chunk isKindOfClass:[NSData class]]) {
                                data = chunk;
                            } else if ([chunk isKindOfClass:[NSString class]]) {
                                data = [(NSString*)chunk dataUsingEncoding:NSUTF8StringEncoding];
                            }
                            [(id<NSURLConnectionDataDelegate>)(self.delegate) connection:self didReceiveData:data];
                        }
                    } else {
                        [(id<NSURLConnectionDataDelegate>)(self.delegate) connection:self didReceiveData:nil];
                    }
                }
            }
        }
        if ([self.delegate respondsToSelector:selConnectionDidFinishLoading]) {
            [(id<NSURLConnectionDataDelegate>)(self.delegate) connectionDidFinishLoading:self];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(connection:didFailWithError:)]) {
            [self.delegate connection:self didFailWithError:self.error];
        }
    }
}

@end
