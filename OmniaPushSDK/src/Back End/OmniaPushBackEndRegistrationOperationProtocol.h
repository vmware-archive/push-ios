//
//  OmniaPushBackEndRegistrationOperationProtocol.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-27.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OmniaPushRegistrationParameters;
@class OmniaPushBackEndRegistrationResponseData;

@protocol OmniaPushBackEndRegistrationOperationProtocol <NSObject>

- (instancetype)initDeviceRegistration:(NSData *)apnsDeviceToken
                            parameters:(OmniaPushRegistrationParameters *)parameters
                             onSuccess:(OmniaPushBackEndSuccessBlock)successBlock
                             onFailure:(OmniaPushBackEndFailureBlock)failBlock;


@end
