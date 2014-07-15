//
//  MSSPushTest.h
//  MSSPush
//
//  Created by DX123-XL on 3/12/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "MSSPushClient.h"

@interface MSSPushClient (TestingHeader)

+ (void)sendRegisterRequestWithParameters:(MSSParameters *)parameters
                              deviceToken:(NSData *)deviceToken
                                  success:(void (^)(void))successBlock
                                  failure:(void (^)(NSError *error))failureBlock;

+ (void)sendUpdateRegistrationRequestWithParameters:(MSSParameters *)parameters
                                deviceToken:(NSData *)deviceToken
                                    success:(void (^)(void))successBlock
                                    failure:(void (^)(NSError *error))failureBlock;


@end
