//
//  OmniaPushOperationQueueProvider.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-08.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OmniaPushOperationQueueProvider : NSObject

+ (NSOperationQueue *) workerQueue;
+ (void) setWorkerQueue:(NSOperationQueue *) workerQueue;

@end
