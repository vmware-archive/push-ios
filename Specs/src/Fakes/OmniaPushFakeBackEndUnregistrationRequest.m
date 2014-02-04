//
//  OmniaPushFakeBackEndUnregistrationRequest.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-04.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushFakeBackEndUnregistrationRequest.h"

@interface OmniaPushFakeBackEndUnregistrationRequest ()

@property (nonatomic) NSError *error;
@property (nonatomic) BOOL isSuccessfulRequest;

@end

@implementation OmniaPushFakeBackEndUnregistrationRequest

- (void)setupForSuccess
{
    self.isSuccessfulRequest = YES;
}

- (void)setupForFailureWithError:(NSError*)error
{
    self.isSuccessfulRequest = NO;
    self.error = error;
}

- (void) startDeviceUnregistration:(NSString*)backEndDeviceUuid
                         onSuccess:(OmniaPushBackEndUnregistrationComplete)successBlock
                         onFailure:(OmniaPushBackEndUnregistrationFailed)failBlock
{
    if (self.isSuccessfulRequest) {
        successBlock();
    } else {
        failBlock(self.error);
    }
}

@end
