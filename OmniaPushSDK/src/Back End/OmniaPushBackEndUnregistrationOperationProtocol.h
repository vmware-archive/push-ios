//
//  OmniaPushBackEndUnregistrationOperation.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OmniaPushBackEndUnregistrationComplete) (void);
typedef void (^OmniaPushBackEndUnregistrationFailed) (NSError *error);

@protocol OmniaPushBackEndUnregistrationOperation <NSObject>

- (instancetype)initDeviceUnregistrationWithUUID:(NSString *)backEndDeviceUUID
                                       onSuccess:(OmniaPushBackEndUnregistrationComplete)successBlock
                                       onFailure:(OmniaPushBackEndUnregistrationFailed)failBlock;

@end
