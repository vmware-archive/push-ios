//
//  OmniaPushSDKTest.h
//  OmniaPushSDK
//
//  Created by DX123-XL on 3/12/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushSDK.h"

@interface OmniaPushSDK (TestingHeader)

+ (void)sendRegisterRequestWithParameters:(OmniaPushRegistrationParameters *)parameters
                                 devToken:(NSData *)devToken
                             successBlock:(void (^)(void))successBlock
                             failureBlock:(void (^)(NSError *error))failureBlock;

+ (void)sendUnregisterRequestWithParameters:(OmniaPushRegistrationParameters *)parameters
                                   devToken:(NSData *)devToken
                               successBlock:(void (^)(void))successBlock
                               failureBlock:(void (^)(NSError *error))failureBlock;


@end