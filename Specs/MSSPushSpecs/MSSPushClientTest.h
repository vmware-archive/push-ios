//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
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
