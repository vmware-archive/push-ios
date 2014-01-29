//
//  OmniaPushFakeNSURLConnectionFactory.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OmniaPushNSURLConnectionFactory.h"

@interface OmniaPushFakeNSURLConnectionFactory : NSObject<OmniaPushNSURLConnectionFactory>

- (void) setupForFailureWithError:(NSError*)error;
- (void) setupForSuccessWithResponse:(NSURLResponse*)response withDataInChunks:(NSArray*)chunks;

@end
