//
//  OmniaPushBackEndRegistrationRequestProvider.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-27.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushBackEndRegistrationRequestProvider.h"
#import "OmniaPushBackEndRegistrationRequest.h"

static NSObject<OmniaPushBackEndRegistrationRequest> *_request;

@implementation OmniaPushBackEndRegistrationRequestProvider

+ (NSObject<OmniaPushBackEndRegistrationRequest>*) request
{
    return _request;
    // TODO - create default request if nil
}

+ (void) setRequest:(NSObject<OmniaPushBackEndRegistrationRequest>*)request
{
    _request = request;
}

@end
