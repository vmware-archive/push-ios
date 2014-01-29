//
//  OmniaPushFakeNSURLConnection.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OmniaPushFakeNSURLConnection : NSURLConnection

- (void) setupForFailureWithError:(NSError*)error;
- (void) setupForSuccessWithResponse:(NSURLResponse*)response withDataInChunks:(NSArray*)chunks;

@end
