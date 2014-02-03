//
//  OmniaPushBackEndUnregistrationRequest.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-03.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OmniaPushBackEndUnregistrationComplete) (void);
typedef void (^OmniaPushBackEndUnregistrationFailed) (NSError *error);

@protocol OmniaPushBackEndUnregistrationRequest <NSObject>

- (void) startDeviceUnregistration:(NSString*)backEndDeviceUuid
                         onSuccess:(OmniaPushBackEndUnregistrationComplete)successBlock
                         onFailure:(OmniaPushBackEndUnregistrationFailed)failBlock;

@end
