//
//  OmniaPushNSURLConnectionProvider.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushNSURLConnectionProvider.h"
#import "OmniaPushNSURLConnectionFactory.h"
#import "OmniaPushNSURLConnectionFactoryImpl.h"

static NSObject<OmniaPushNSURLConnectionFactory>* _factory;

@implementation OmniaPushNSURLConnectionProvider

+ (NSURLConnection*) getNSURLConnectionWithRequest:(NSURLRequest*)request
                                          delegate:(id<NSURLConnectionDelegate>)delegate
{
    if (_factory == nil) {
        _factory = [[OmniaPushNSURLConnectionFactoryImpl alloc] init];
    }
    return [_factory getNSURLConnectionWithRequest:request delegate:delegate];
}

+ (void) setFactory:(NSObject<OmniaPushNSURLConnectionFactory>*)factory
{
    _factory = factory;
}

@end
