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
#import "OmniaPushBackEndConnection.h"
#import "OmniaPushAppDelegateOperation.h"

#import "OmniaPushApplicationDelegateSwitcher.h"
#import "OmniaPushApplicationDelegateSwitcherProvider.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaPushDebug.h"

#import "OmniaPushErrorUtil.h"
#import "OmniaPushErrors.h"

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
                       success:(void (^)(NSURLResponse *response, id responseObject))success
                       failure:(void (^)(NSURLResponse *response, NSError *error))failure
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"parameters may not be nil"];
    }

    NSOperation *appDelegateOperation = [OmniaPushSDK appDelegateOperationWithRegistrationParameters:parameters
                                                                                        successBlock:success
                                                                                        failureBlock:failure];
    [[self omniaPushOperationQueue] addOperation:appDelegateOperation];
}

+ (void)sendUnregisterRequestWithParameters:(OmniaPushRegistrationParameters *)parameters
                                   devToken:(NSData *)devToken
                               successBlock:(void (^)(NSURLResponse *response, id responseObject))successBlock
                               failureBlock:(void (^)(NSURLResponse *response, NSError *error))failureBlock
{
    [OmniaPushBackEndConnection sendUnregistrationRequestOnQueue:[self omniaPushOperationQueue]
                                                    withDeviceID:[OmniaPushPersistentStorage loadBackEndDeviceID]
                                                         success:^(NSURLResponse *response, NSData *data) {
                                                             OmniaPushCriticalLog(@"Unregistration with the back-end server succeeded.");
                                                             [self sendRegisterRequestWithParameters:parameters devToken:devToken successBlock:successBlock failureBlock:failureBlock];
                                                         }
                                                         failure:^(NSURLResponse *response, NSError *error) {
                                                             OmniaPushCriticalLog(@"Unregistration with the back-end server failed. Error: \"%@\".", error.localizedDescription);
                                                             OmniaPushLog(@"Nevertheless, registration will be attempted.");
                                                             [self sendRegisterRequestWithParameters:parameters devToken:devToken successBlock:successBlock failureBlock:failureBlock];
                                                         }];
}

+ (void)sendRegisterRequestWithParameters:(OmniaPushRegistrationParameters *)parameters
                                 devToken:(NSData *)devToken
                             successBlock:(void (^)(NSURLResponse *response, id responseObject))successBlock
                             failureBlock:(void (^)(NSURLResponse *response, NSError *error))failureBlock
{
    void (^registrationSuccessfulBlock)(NSURLResponse *response, id responseData) = registrationSuccessfulBlock = ^(NSURLResponse *response, id responseData) {
        NSError *error;
        
        if (!responseData || ([responseData isKindOfClass:[NSData class]] && [(NSData *)responseData length] <= 0)) {
            error = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationEmptyResponseData localizedDescription:@"Response body is empty when attempting registration with back-end server"];
            failureBlock(response, error);
            return;
        }
        
        OmniaPushBackEndRegistrationResponseData *parsedData = [OmniaPushBackEndRegistrationResponseData fromJsonData:responseData error:&error];
        
        if (error) {
            failureBlock(response, error);
            return;
        }
        
        OmniaPushCriticalLog(@"Registration with back-end succeded. Device ID: \"%@\".", parsedData.deviceUuid);
        [OmniaPushPersistentStorage saveBackEndDeviceID:parsedData.deviceUuid];
        [OmniaPushPersistentStorage saveReleaseUuid:parameters.releaseUuid];
        [OmniaPushPersistentStorage saveReleaseSecret:parameters.releaseSecret];
        [OmniaPushPersistentStorage saveDeviceAlias:parameters.deviceAlias];
        
        successBlock(response, parsedData);
    };
    [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:[self omniaPushOperationQueue]
                                                withParameters:parameters
                                                      devToken:devToken
                                                       success:registrationSuccessfulBlock
                                                       failure:failureBlock];
}

+ (OmniaPushAppDelegateOperation *)appDelegateOperationWithRegistrationParameters:(OmniaPushRegistrationParameters *)parameters
                                                                     successBlock:(void (^)(NSURLResponse *response, id responseObject))successBlock
                                                                     failureBlock:(void (^)(NSURLResponse *response, NSError *error))failureBlock
{
    void (^success)(NSURLResponse *response, NSData *devToken) = ^(NSURLResponse *response, NSData *devToken) {
        
        if ([self.class isBackEndUnregistrationRequiredForDevToken:devToken parameters:parameters]) {
            [OmniaPushPersistentStorage saveBackEndDeviceID:nil];
            [self sendUnregisterRequestWithParameters:parameters devToken:devToken successBlock:successBlock failureBlock:failureBlock];
            
        } else if([self.class isBackEndRegistrationRequiredForDevToken:devToken parameters:parameters]) {
            [self sendRegisterRequestWithParameters:parameters devToken:devToken successBlock:successBlock failureBlock:failureBlock];
            
        } else {
            successBlock(nil, devToken);
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
