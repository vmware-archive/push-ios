//
//  OmniaPushBackEndConnection.h
//  OmniaPushSDK
//
//  Created by DX123-XL on 3/4/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OmniaPushRegistrationParameters;

@interface OmniaPushBackEndConnection : NSURLConnection

+ (void)sendUnregistrationRequestOnQueue:(NSOperationQueue *)queue
                            withDeviceID:(NSString *)deviceID
                                 success:(void (^)(NSURLResponse *response, NSData *data))success
                                 failure:(void (^)(NSURLResponse *response, NSError *error))failure;

+ (void)sendRegistrationRequestOnQueue:(NSOperationQueue *)queue
                        withParameters:(OmniaPushRegistrationParameters *)parameters
                              devToken:(NSData *)devToken
                               success:(void (^)(NSURLResponse *response, NSData *data))success
                               failure:(void (^)(NSURLResponse *response, NSError *error))failure;


@end
