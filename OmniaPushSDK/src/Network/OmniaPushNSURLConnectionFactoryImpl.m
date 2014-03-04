//
//  OmniaPushNSURLConnectionFactoryImpl.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushNSURLConnectionFactoryImpl.h"
#import "OmniaPushNSURLConnectionFactory.h"

@implementation OmniaPushNSURLConnectionFactoryImpl

+ (NSURLConnection *) connectionWithRequest:(NSURLRequest *)request
                                   delegate:(id<NSURLConnectionDelegate>)delegate
{
    return [NSURLConnection connectionWithRequest:request delegate:delegate];
}

@end
