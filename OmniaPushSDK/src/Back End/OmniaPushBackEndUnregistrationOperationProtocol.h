//
//  OmniaPushBackEndUnregistrationOperation.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OmniaPushBackEndSuccessBlock) (id responseData);
typedef void (^OmniaPushBackEndFailureBlock) (NSError *error);

@protocol OmniaPushBackEndUnregistrationOperation <NSObject>

- (instancetype)initDeviceUnregistrationWithUUID:(NSString *)backEndDeviceUUID
                                       onSuccess:(OmniaPushBackEndSuccessBlock)successBlock
                                       onFailure:(OmniaPushBackEndFailureBlock)failBlock;

@end
