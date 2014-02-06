//
//  OmniaPushFakeBackEndRegistrationRequestt.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-27.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushFakeBackEndRegistrationRequest.h"
#import "OmniaPushBackEndRegistrationRequest.h"
#import "OmniaPushRegistrationParameters.h"

@interface OmniaPushFakeBackEndRegistrationRequest ()

@property (nonatomic) OmniaPushBackEndRegistrationResponseData *responseData;
@property (nonatomic) NSError *error;
@property (nonatomic) BOOL isSuccessfulRequest;

@end

@implementation OmniaPushFakeBackEndRegistrationRequest

- (void)setupForSuccessWithResponseData:(OmniaPushBackEndRegistrationResponseData*)responseData
{
    self.isSuccessfulRequest = YES;
    self.responseData = responseData;
}

- (void)setupForFailureWithError:(NSError*)error
{
    self.isSuccessfulRequest = NO;
    self.error = error;
}

- (void) startDeviceRegistration:(NSData*)apnsDeviceToken
                      parameters:(OmniaPushRegistrationParameters*)parameters
                       onSuccess:(OmniaPushBackEndRegistrationComplete)successBlock
                       onFailure:(OmniaPushBackEndRegistrationFailed)failBlock
{
    if (apnsDeviceToken == nil) {
        [NSException raise:NSInvalidArgumentException format:@"apnsDeviceToken may not be nil"];
    }
    if (parameters == nil) {
        [NSException raise:NSInvalidArgumentException format:@"parameters may not be nil"];
    }
    if (successBlock == nil) {
        [NSException raise:NSInvalidArgumentException format:@"successBlock may not be nil"];
    }
    if (failBlock == nil) {
        [NSException raise:NSInvalidArgumentException format:@"failBlock may not be nil"];
    }
    
    if (self.isSuccessfulRequest) {
        successBlock(self.responseData);
    } else {
        failBlock(self.error);
    }
}

@end
