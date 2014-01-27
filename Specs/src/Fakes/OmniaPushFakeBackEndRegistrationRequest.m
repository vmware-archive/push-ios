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
    if (self.isSuccessfulRequest) {
        successBlock(self.responseData);
    } else {
        failBlock(self.error);
    }
}

@end
