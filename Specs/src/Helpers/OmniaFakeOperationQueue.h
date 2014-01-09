//
//  OmniaFakeOperationQueue.h
//  OmniaPushSDK
//
//  Copyright (c) 2014 Omnia. All rights reserved.
//
//  From PivotalCoreKit: https://github.com/pivotal/PivotalCoreKit (MIT License)

#import <Foundation/Foundation.h>

@interface OmniaFakeOperationQueue : NSOperationQueue

@property (nonatomic) BOOL runSynchronously;

- (void) reset;
- (id) runNextOperation;
- (void) drain;
- (BOOL) didFinishOperation:(Class)classOfOperation;

@end