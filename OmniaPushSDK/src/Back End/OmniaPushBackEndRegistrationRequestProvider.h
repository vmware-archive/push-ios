//
//  OmniaPushBackEndRegistrationRequestProvider.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-27.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OmniaPushBackEndRegistrationRequest;

@interface OmniaPushBackEndRegistrationRequestProvider : NSObject

+ (NSObject<OmniaPushBackEndRegistrationRequest>*) request;
+ (void) setRequest:(NSObject<OmniaPushBackEndRegistrationRequest>*)request;

@end
