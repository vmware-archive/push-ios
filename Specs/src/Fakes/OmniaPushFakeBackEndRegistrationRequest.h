//
//  OmniaPushFakeBackEndRegistrationRequest.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-27.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniaPushBackEndRegistrationRequest.h"

@interface OmniaPushFakeBackEndRegistrationRequest : NSObject<OmniaPushBackEndRegistrationRequest>

- (void)setupForSuccessWithResponseData:(OmniaPushBackEndRegistrationResponseData*)responseData;
- (void)setupForFailureWithError:(NSError*)error;

@end
