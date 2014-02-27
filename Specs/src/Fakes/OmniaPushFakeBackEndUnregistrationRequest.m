//
//  OmniaPushFakeBackEndUnregistrationRequest.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-04.
//  Copyright (c) 2014 Pivotal. All rights reserved.
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
    if (backEndDeviceUuid == nil) {
        [NSException raise:NSInvalidArgumentException format:@"backEndDeviceUuid may not be nil"];
    }
    if (successBlock == nil) {
        [NSException raise:NSInvalidArgumentException format:@"successBlock may not be nil"];
    }
    if (failBlock == nil) {
        [NSException raise:NSInvalidArgumentException format:@"failBlock may not be nil"];
    }

    if (self.isSuccessfulRequest) {
        successBlock();
    } else {
        failBlock(self.error);
    }
}

@end
