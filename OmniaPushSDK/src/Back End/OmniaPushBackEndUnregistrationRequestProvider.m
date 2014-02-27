//
//  OmniaPushBackEndUnregistrationRequestProvider.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndUnregistrationRequestProvider.h"
#import "OmniaPushBackEndUnregistrationRequest.h"
#import "OmniaPushBackEndUnregistrationRequestImpl.h"

static NSObject<OmniaPushBackEndUnregistrationRequest> *_request;

@implementation OmniaPushBackEndUnregistrationRequestProvider

+ (NSObject<OmniaPushBackEndUnregistrationRequest>*) request
{
    if (_request == nil) {
        _request = [[OmniaPushBackEndUnregistrationRequestImpl alloc] init];
    }
    return _request;
}

+ (void) setRequest:(NSObject<OmniaPushBackEndUnregistrationRequest>*)request
{
    _request = request;
}

@end
