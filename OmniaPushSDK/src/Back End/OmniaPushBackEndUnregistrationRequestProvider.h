//
//  OmniaPushBackEndUnregistrationRequestProvider.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-03.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OmniaPushBackEndUnregistrationRequest;

@interface OmniaPushBackEndUnregistrationRequestProvider : NSObject

+ (NSObject<OmniaPushBackEndUnregistrationRequest>*) request;
+ (void) setRequest:(NSObject<OmniaPushBackEndUnregistrationRequest>*)request;

@end
