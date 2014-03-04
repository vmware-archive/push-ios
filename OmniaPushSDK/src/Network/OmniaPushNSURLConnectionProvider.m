//
//  OmniaPushNSURLConnectionProvider.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushNSURLConnectionProvider.h"
#import "OmniaPushNSURLConnectionFactory.h"
#import "OmniaPushNSURLConnectionFactoryImpl.h"

static Class<OmniaPushNSURLConnectionFactory> _factoryClass;

@implementation OmniaPushNSURLConnectionProvider

+ (NSURLConnection *) connectionWithRequest:(NSURLRequest *)request
                                   delegate:(id<NSURLConnectionDelegate>)delegate
{
    if (_factoryClass == nil) {
        _factoryClass = [OmniaPushNSURLConnectionFactoryImpl class];
    }
    return [_factoryClass connectionWithRequest:request delegate:delegate];
}

+ (void) setFactory:(Class<OmniaPushNSURLConnectionFactory>)factoryClass
{
    _factoryClass = factoryClass;
}

@end
