//
//  PCFPushSDKTest.h
//  PCFPushSDK
//
//  Created by DX123-XL on 3/12/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "PCFPushSDK.h"

@interface PCFPushSDK (TestingHeader)

+ (void)sendRegisterRequestWithParameters:(PCFPushParameters *)parameters
                                 devToken:(NSData *)devToken
                             successBlock:(void (^)(void))successBlock
                             failureBlock:(void (^)(NSError *error))failureBlock;

+ (void)sendUnregisterRequestWithParameters:(PCFPushParameters *)parameters
                                   devToken:(NSData *)devToken
                               successBlock:(void (^)(void))successBlock
                               failureBlock:(void (^)(NSError *error))failureBlock;


@end
