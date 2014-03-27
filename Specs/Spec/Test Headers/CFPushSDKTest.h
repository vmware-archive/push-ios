//
//  CFPushSDKTest.h
//  CFPushSDK
//
//  Created by DX123-XL on 3/12/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "CFPushSDK.h"

@interface CFPushSDK (TestingHeader)

+ (void)sendRegisterRequestWithParameters:(CFPushParameters *)parameters
                                 devToken:(NSData *)devToken
                             successBlock:(void (^)(void))successBlock
                             failureBlock:(void (^)(NSError *error))failureBlock;

+ (void)sendUnregisterRequestWithParameters:(CFPushParameters *)parameters
                                   devToken:(NSData *)devToken
                               successBlock:(void (^)(void))successBlock
                               failureBlock:(void (^)(NSError *error))failureBlock;


@end