//
//  OmniaPushOperationQueueProvider.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-08.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushOperationQueueProvider.h"

static NSOperationQueue *_workerQueue;
static NSOperationQueue *_mainQueue;

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

+ (NSOperationQueue *) mainQueue
{
    if (_mainQueue == nil) {
        _mainQueue = [NSOperationQueue mainQueue];
    }
    return _mainQueue;
}

+ (void) setMainQueue:(NSOperationQueue *) mainQueue
{
    _mainQueue = mainQueue;
}

@end
