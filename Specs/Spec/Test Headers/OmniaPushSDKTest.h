//
//  OmniaPushSDKTest.h
//  OmniaPushSDK
//
//  Created by DX123-XL on 3/12/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushSDK.h"

@interface OmniaPushSDK (TestingHeader)

+ (NSOperationQueue *)omniaPushOperationQueue;

+ (void)setWorkerQueue:(NSOperationQueue *)workerQueue;

+ (void)sendRegisterRequestWithParameters:(OmniaPushRegistrationParameters *)parameters
                                 devToken:(NSData *)devToken
                             successBlock:(void (^)(NSURLResponse *response, id responseObject))successBlock
                             failureBlock:(void (^)(NSURLResponse *response, NSError *error))failureBlock;

+ (void)sendUnregisterRequestWithParameters:(OmniaPushRegistrationParameters *)parameters
                                   devToken:(NSData *)devToken
                               successBlock:(void (^)(NSURLResponse *response, id responseObject))successBlock
                               failureBlock:(void (^)(NSURLResponse *response, NSError *error))failureBlock;


@end