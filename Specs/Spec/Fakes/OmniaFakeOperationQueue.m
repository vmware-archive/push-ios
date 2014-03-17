//
//  OmniaFakeOperationQueue.m
//  OmniaPushSDK
//
//  Copyright (c) 2014 Pivotal. All rights reserved.
//
//  From PivotalCoreKit: https://github.com/pivotal/PivotalCoreKit (MIT License)

#import "OmniaFakeOperationQueue.h"

@interface OmniaFakeOperationQueue ()

@property (nonatomic) NSMutableArray *mutableOperations;
@property (nonatomic) NSMutableArray *operationsFinished;

@end

@implementation OmniaFakeOperationQueue

- (id) init
{
    if (self = [super init]) {
        self.suspended = YES;
        [self reset];
    }
    return self;
}

- (void) dealloc
{
    self.mutableOperations = nil;
}

- (void) reset
{
    self.mutableOperations = [NSMutableArray array];
    self.operationsFinished = [NSMutableArray array];
}

- (void) setSuspended:(BOOL)b
{
    // override for unit tests.  supposed to do nothing.
}

- (void) addOperation:(NSOperation *)op
{
    if (self.runSynchronously) {
        [self performOperationAndWait:op];
    } else {
        [self.mutableOperations addObject:op];
    }
}

- (void) addOperations:(NSArray *)operations waitUntilFinished:(BOOL)wait
{
    for (id op in operations) {
        
        id operation;
        if (![op isKindOfClass:[NSOperation class]]) {
            operation = [NSBlockOperation blockOperationWithBlock:[op copy]];
        } else {
            operation = op;
        }
        
        if (wait) {
            [self performOperationAndWait:operation];
        } else {
            [self.mutableOperations addObject:operation];
        }
    }
}

- (void)addOperationWithBlock:(void (^)(void))block
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:[block copy]];
    if (self.runSynchronously) {
        [self performOperationAndWait:blockOperation];
    } else {
        [self.mutableOperations addObject:blockOperation];
    }
}

- (NSArray *) operations
{
    return self.mutableOperations;
}

- (NSUInteger) operationCount
{
    return self.mutableOperations.count;
}

- (void) performOperationAndWait:(NSOperation *)op
{
    [op start];
    [op waitUntilFinished];
    [self.operationsFinished addObject:[op class]];
}

- (id) runNextOperation
{
    if (self.mutableOperations.count == 0) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't run an operation that doesn't exist" userInfo:nil] raise];
    }
    id operation = [self.mutableOperations objectAtIndex:0];
    if ([operation isKindOfClass:[NSOperation class]]) {
        [self performOperationAndWait:operation];
    } else {
        ((void (^)())operation)();
    }
    [self.mutableOperations removeObject:operation];
    return operation;
}

- (void) drain
{
    while ([self operationCount] > 0) {
        [self runNextOperation];
    }
}

- (BOOL) didFinishOperation:(Class)classOfOperation
{
    return [self.operationsFinished containsObject:classOfOperation];
}

@end
