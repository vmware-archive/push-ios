//
//  PCFPushSDKTest.h
//  PCFPushSDK
//
//  Created by DX123-XL on 3/12/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "PCFPushClient.h"

@interface PCFPushClient (TestingHeader)

+ (void)sendRegisterRequestWithParameters:(PCFParameters *)parameters
                              deviceToken:(NSData *)deviceToken
                                  success:(void (^)(void))successBlock
                                  failure:(void (^)(NSError *error))failureBlock;

+ (void)sendUpdateRegistrationRequestWithParameters:(PCFParameters *)parameters
                                deviceToken:(NSData *)deviceToken
                                    success:(void (^)(void))successBlock
                                    failure:(void (^)(NSError *error))failureBlock;


@end
