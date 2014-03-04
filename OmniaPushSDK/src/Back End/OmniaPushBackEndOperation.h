//
//  OmniaPushBackEndOperation.h
//  OmniaPushSDK
//
//  Created by DX123-XL on 3/4/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OmniaPushBackEndUnregistrationOperationProtocol.h"

@interface OmniaPushBackEndOperation : NSOperation <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSOutputStream *outputStream;
@property (readonly, nonatomic, strong) NSError *resultantError;
@property (readonly, nonatomic, strong) NSData *responseData;

- (id)initWithRequest:(NSURLRequest *)request
              success:(OmniaPushBackEndSuccessBlock)success
              failure:(OmniaPushBackEndFailureBlock)failure;

- (void)returnError:(NSError *)error;

@end
