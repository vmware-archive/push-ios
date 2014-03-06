//
//  OmniaPushSDK.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "OmniaPushSDK.h"

//Operations
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushBackEndUnregistrationOperationProtocol.h"
#import "OmniaPushBackEndUnregistrationOperationImpl.h"
#import "OmniaPushBackEndRegistrationOperationProtocol.h"
#import "OmniaPushBackEndRegistrationOperationImpl.h"
#import "OmniaPushAppDelegateOperation.h"

#import "OmniaPushApplicationDelegateSwitcher.h"
#import "OmniaPushApplicationDelegateSwitcherProvider.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaPushDebug.h"

//Models
#import "OmniaPushBackEndRegistrationResponseData.h"

NSString *const OmniaPushErrorDomain = @"OmniaPushErrorDomain";

static NSString *deviceID = nil;

#pragma mark - OmniaOperationQueue

@interface OmniaOperationQueue : NSOperationQueue
@property (nonatomic) NSObject<UIApplicationDelegate> *applicationDelegate;
@end

@implementation OmniaOperationQueue
@end

#pragma mark - OmniaPushSDK

@implementation OmniaPushSDK

+ (OmniaOperationQueue *)omniaPushOperationQueue {
    static OmniaOperationQueue *workerQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        workerQueue = [[OmniaOperationQueue alloc] init];
        
        //The UIApplication delegate will be deallocated unless it is strongly retained.
        workerQueue.applicationDelegate = [[self sharedApplication] delegate];
        workerQueue.maxConcurrentOperationCount = 1;
        workerQueue.name = @"OmniaPushOperationQueue";
    });
    return workerQueue;
}

+ (void) registerWithParameters:(OmniaPushRegistrationParameters *)parameters
{
    [self registerWithParameters:parameters success:nil failure:nil];
}

+ (void)registerWithParameters:(OmniaPushRegistrationParameters *)parameters
                       success:(void (^)(id responseObject))success
                       failure:(void (^)(NSError *error))failure
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"parameters may not be nil"];
    }

    NSOperation *appDelegateOperation = [OmniaPushSDK appDelegateOperationWithRegistrationParameters:parameters
                                                                                        successBlock:success
                                                                                        failureBlock:failure];
    [[self omniaPushOperationQueue] addOperation:appDelegateOperation];
}

+ (NSOperation *)unregisterOperation
{
    NSOperation *unregisterOperation = [[OmniaPushBackEndUnregistrationOperation alloc] initDeviceUnregistrationWithUUID:[OmniaPushPersistentStorage loadBackEndDeviceID]
                                                                                                               onSuccess:^(NSData *devToken){
                                                                                                                   OmniaPushCriticalLog(@"Unregistration with the back-end server succeeded.");
                                                                                                               }
                                                                                                               onFailure:^(NSError *error) {
                                                                                                                   OmniaPushCriticalLog(@"Unregistration with the back-end server failed. Error: \"%@\".", error.localizedDescription);
                                                                                                                   OmniaPushLog(@"Nevertheless, registration will be attempted.");
                                                                                                               }];
    return unregisterOperation;
}

+ (NSOperation *)registerOperationWithParameters:(OmniaPushRegistrationParameters *)parameters
                                        devToken:(NSData *)devToken
                                    successBlock:(void (^)(id responseObject))successBlock
                                    failureBlock:(void (^)(NSError *error))failureBlock
{
    OmniaPushBackEndSuccessBlock registrationSuccessfulBlock = ^(id responseData) {
        OmniaPushBackEndRegistrationResponseData *responseObject = responseData;
        
        OmniaPushCriticalLog(@"Registration with back-end succeded. Device ID: \"%@\".", responseObject.deviceUuid);
        [OmniaPushPersistentStorage saveBackEndDeviceID:responseObject.deviceUuid];
        [OmniaPushPersistentStorage saveReleaseUuid:parameters.releaseUuid];
        [OmniaPushPersistentStorage saveReleaseSecret:parameters.releaseSecret];
        [OmniaPushPersistentStorage saveDeviceAlias:parameters.deviceAlias];
        successBlock(responseObject);
    };
    NSOperation *registerOperation = [[OmniaPushBackEndRegistrationOperation alloc] initDeviceRegistrationWithDevToken:devToken
                                                                                                            parameters:parameters
                                                                                                             onSuccess:registrationSuccessfulBlock
                                                                                                             onFailure:failureBlock];
    return registerOperation;
    
}

+ (OmniaPushAppDelegateOperation *)appDelegateOperationWithRegistrationParameters:(OmniaPushRegistrationParameters *)parameters
                                                                     successBlock:(void (^)(id responseObject))successBlock
                                                                     failureBlock:(void (^)(NSError *error))failureBlock
{
    void (^success)(NSData *devToken) = ^(NSData *devToken) {
        NSOperation *registerOperation = [self.class registerOperationWithParameters:parameters devToken:devToken successBlock:successBlock failureBlock:failureBlock];
        
        if ([self.class isBackEndUnregistrationRequiredForDevToken:devToken parameters:parameters]) {
            [OmniaPushPersistentStorage saveBackEndDeviceID:nil];
            NSOperation *unregisterOperation = [OmniaPushSDK unregisterOperation];
            [unregisterOperation addDependency:registerOperation];
            [[self omniaPushOperationQueue] addOperation:unregisterOperation];
            
        } else if([self.class isBackEndRegistrationRequiredForDevToken:devToken parameters:parameters]) {
            [[self omniaPushOperationQueue] addOperation:registerOperation];
            
        } else {
            successBlock(devToken);
        }
    };
    OmniaPushAppDelegateOperation *appDelegateOperation = [[OmniaPushAppDelegateOperation alloc] initWithApplication:[self sharedApplication]
                                                                                             remoteNotificationTypes:parameters.remoteNotificationTypes
                                                                                                             success:success
                                                                                                             failure:failureBlock];
    return appDelegateOperation;
}

+ (UIApplication *)sharedApplication
{
    return [UIApplication sharedApplication];
}

+ (BOOL)isBackEndUnregistrationRequiredForDevToken:(NSData *)devToken
                                         parameters:(OmniaPushRegistrationParameters *)parameters
{
    // If not currently registered with the back-end then unregistration is not required
    if (![OmniaPushPersistentStorage loadAPNSDeviceToken]) {
        return NO;
    }
    
    return [self.class newParameters:parameters mismatchLocalParametersForDevToken:devToken];

}

+ (BOOL)isBackEndRegistrationRequiredForDevToken:(NSData *)devToken
                                      parameters:(OmniaPushRegistrationParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if (![OmniaPushPersistentStorage loadBackEndDeviceID]) {
        return YES;
    }
    
    return [self.class newParameters:parameters mismatchLocalParametersForDevToken:devToken];
    
}

+ (BOOL)newParameters:(OmniaPushRegistrationParameters *)parameters mismatchLocalParametersForDevToken:(NSData *)devToken
{
    if (![devToken isEqualToData:[OmniaPushPersistentStorage loadAPNSDeviceToken]]) {
        OmniaPushLog(@"APNS returned a different APNS token. Unregistration and re-registration will be required.");
        return YES;
    }
    
    // If any of the registration parameters are different then unregistration is required
    if (![parameters.releaseUuid isEqualToString:[OmniaPushPersistentStorage loadReleaseUuid]]) {
        OmniaPushLog(@"Parameters specify a different releaseUuid. Unregistration and re-registration will be required.");
        return YES;
    }
    
    if (![parameters.releaseSecret isEqualToString:[OmniaPushPersistentStorage loadReleaseSecret]]) {
        OmniaPushLog(@"Parameters specify a different releaseSecret. Unregistration and re-registration will be required.");
        return YES;
    }
    
    if (![parameters.deviceAlias isEqualToString:[OmniaPushPersistentStorage loadDeviceAlias]]) {
        OmniaPushLog(@"Parameters specify a different deviceAlias. Unregistration and re-registration will be required.");
        return YES;
    }
    
    return NO;
}

@end
