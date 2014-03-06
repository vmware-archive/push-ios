//
//  OmniaPushBackEndRegistrationRequestProvider.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-27.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndRegistrationRequestProvider.h"
#import "OmniaPushBackEndRegistrationOperationImpl.h"

static NSObject<OmniaPushBackEndRegistrationOperationProtocol> *_operation;

@implementation OmniaPushBackEndRegistrationOperationProvider

+ (NSObject<OmniaPushBackEndRegistrationOperationProtocol> *)operation
{
    if (_operation == nil) {
        _operation = [[OmniaPushBackEndRegistrationOperation alloc] init];
    }
    return _operation;
}

+ (void) setRequest:(NSObject<OmniaPushBackEndRegistrationOperationProtocol> *)operation
{
    _operation = operation;
}

@end
