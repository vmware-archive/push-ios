//
//  PMSSPushSDKTest.h
//  PMSSPushSDK
//
//  Created by DX123-XL on 3/12/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "PMSSPushClient.h"

@interface PMSSPushClient (TestingHeader)

+ (void)sendRegisterRequestWithParameters:(PMSSParameters *)parameters
                              deviceToken:(NSData *)deviceToken
                                  success:(void (^)(void))successBlock
                                  failure:(void (^)(NSError *error))failureBlock;

+ (void)sendUpdateRegistrationRequestWithParameters:(PMSSParameters *)parameters
                                deviceToken:(NSData *)deviceToken
                                    success:(void (^)(void))successBlock
                                    failure:(void (^)(NSError *error))failureBlock;


@end
