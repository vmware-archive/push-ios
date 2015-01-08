//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
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
