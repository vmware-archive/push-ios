//
//  OmniaPushOperationQueueProvider.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-08.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushOperationQueueProvider.h"

static NSOperationQueue *_operationQueue;

@implementation OmniaPushOperationQueueProvider

+ (NSOperationQueue *) operationQueue
{
    if (_operationQueue == nil) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        _operationQueue.name = @"OmniaPushOperationQueue";
    }
    return _operationQueue;
}

+ (void) setOperationQueue:(NSOperationQueue *) operationQueue
{
    _operationQueue = operationQueue;
}

@end
