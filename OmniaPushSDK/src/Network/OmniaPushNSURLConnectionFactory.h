//
//  OmniaPushNSURLConnectionFactory.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OmniaPushNSURLConnectionFactory <NSObject>

- (NSURLConnection*) getNSURLConnectionWithRequest:(NSURLRequest*)request
                                          delegate:(id<NSURLConnectionDelegate>)delegate;

@end
