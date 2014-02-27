//
//  OmniaPushFakeNSURLConnectionFactory.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushFakeNSURLConnectionFactory.h"
#import "OmniaPushFakeNSURLConnection.h"

@interface OmniaPushFakeNSURLConnectionFactory ()

@property (nonatomic) BOOL shouldBeSuccessful;
@property (nonatomic) NSError *error;
@property (nonatomic) NSURLResponse *response;
@property (nonatomic) NSArray *chunks;

@end

@implementation OmniaPushFakeNSURLConnectionFactory

- (NSURLConnection*) getNSURLConnectionWithRequest:(NSURLRequest*)request
                                          delegate:(id<NSURLConnectionDelegate>)delegate
{
    OmniaPushFakeNSURLConnection *fake = [[OmniaPushFakeNSURLConnection alloc] initWithRequest:request delegate:delegate startImmediately:NO];
    if (self.shouldBeSuccessful) {
        [fake setupForSuccessWithResponse:self.response withDataInChunks:self.chunks];
    } else {
        [fake setupForFailureWithError:self.error];
    }
    return fake;
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

@end
