//
//  OmniaPushBackEndRegistrationRequest.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-27.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OmniaPushRegistrationParameters;
@class OmniaPushRegistrationEngine;
@class OmniaPushBackEndRegistrationResponseData;

typedef void (^OmniaPushBackEndRegistrationComplete) (OmniaPushBackEndRegistrationResponseData* responseData);
typedef void (^OmniaPushBackEndRegistrationFailed) (NSError *error);

@protocol OmniaPushBackEndRegistrationRequest <NSObject>

- (void) startDeviceRegistration:(NSData*)apnsDeviceToken
                      parameters:(OmniaPushRegistrationParameters*)parameters
                       onSuccess:(OmniaPushBackEndRegistrationComplete)successBlock
                       onFailure:(OmniaPushBackEndRegistrationFailed)failBlock;


@end
