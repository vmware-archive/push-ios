//
//  OmniaPushBackEndRegistrationRequestProvider.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-27.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndRegistrationRequestProvider.h"
#import "OmniaPushBackEndRegistrationRequest.h"
#import "OmniaPushBackEndRegistrationRequestImpl.h"

static NSObject<OmniaPushBackEndRegistrationRequest> *_request;

@implementation OmniaPushBackEndRegistrationRequestProvider

+ (NSObject<OmniaPushBackEndRegistrationRequest> *) request
{
    if (_request == nil) {
        _request = [[OmniaPushBackEndRegistrationRequestImpl alloc] init];
    }
    return _request;
}

+ (void) setRequest:(NSObject<OmniaPushBackEndRegistrationRequest> *)request
{
    _request = request;
}

@end
