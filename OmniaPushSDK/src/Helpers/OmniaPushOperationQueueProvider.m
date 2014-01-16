//
//  OmniaPushOperationQueueProvider.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-08.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushOperationQueueProvider.h"

static NSOperationQueue *_workerQueue;

@implementation OmniaPushOperationQueueProvider

+ (NSOperationQueue *) workerQueue
{
    if (_workerQueue == nil) {
        _workerQueue = [[NSOperationQueue alloc] init];
        _workerQueue.maxConcurrentOperationCount = 1;
        _workerQueue.name = @"OmniaPushOperationQueue";
    }
    return _workerQueue;
}

+ (void) setWorkerQueue:(NSOperationQueue *) workerQueue
{
    _workerQueue = workerQueue;
}

@end
