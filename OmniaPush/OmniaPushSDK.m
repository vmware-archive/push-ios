//
//  OmniaPushSDK.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "OmniaPushSDK.h"

#import "OmniaPushBackEndConnection.h"

#import "OmniaPushAPNSRegistrationRequestOperation.h"

#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaPushDebug.h"

#import "OmniaPushErrorUtil.h"
#import "OmniaPushErrors.h"

//Models
#import "OmniaPushBackEndRegistrationResponseData.h"

NSString *const OmniaPushErrorDomain = @"OmniaPushErrorDomain";

#pragma mark - OmniaOperationQueue

@interface OmniaOperationQueue : NSOperationQueue
@property (nonatomic) NSObject<UIApplicationDelegate> *applicationDelegate;
@end

@implementation OmniaOperationQueue
@end

#pragma mark - OmniaPushSDK

static NSOperationQueue *_workerQueue;
static dispatch_once_t onceToken;

@implementation OmniaPushSDK

+ (NSOperationQueue *)omniaPushOperationQueue {
    dispatch_once(&onceToken, ^{
        if (!_workerQueue) {
            _workerQueue = [[OmniaOperationQueue alloc] init];
            
            if ([_workerQueue respondsToSelector:@selector(applicationDelegate)]) {
                //The UIApplication delegate will be deallocated unless it is strongly retained.
                [(OmniaOperationQueue *)_workerQueue setApplicationDelegate:[[self sharedApplication] delegate]];
            }
            _workerQueue.maxConcurrentOperationCount = 1;
            _workerQueue.name = @"OmniaPushOperationQueue";
        }
    });
    return _workerQueue;
}

+ (void)setWorkerQueue:(NSOperationQueue *)workerQueue
{
    onceToken = 0;
    _workerQueue = workerQueue;
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

    NSOperation *appDelegateOperation = [OmniaPushSDK APNSRegistrationOperationWithParameters:parameters
                                                                                 successBlock:success
                                                                                 failureBlock:failure];
    [self.omniaPushOperationQueue addOperation:appDelegateOperation];
}

+ (void)sendUnregisterRequestWithParameters:(OmniaPushRegistrationParameters *)parameters
                                   devToken:(NSData *)devToken
                               successBlock:(void (^)(NSURLResponse *response, id responseObject))successBlock
                               failureBlock:(void (^)(NSURLResponse *response, NSError *error))failureBlock
{
    [OmniaPushBackEndConnection sendUnregistrationRequestOnQueue:[self omniaPushOperationQueue]
                                                    withDeviceID:[OmniaPushPersistentStorage backEndDeviceID]
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
        
        OmniaPushBackEndRegistrationResponseData *parsedData = [OmniaPushBackEndRegistrationResponseData fromJSONData:responseData error:&error];
        
        if (error) {
            failureBlock(response, error);
            return;
        }
        
        OmniaPushCriticalLog(@"Registration with back-end succeded. Device ID: \"%@\".", parsedData.deviceUUID);
        [OmniaPushPersistentStorage setBackEndDeviceID:parsedData.deviceUUID];
        [OmniaPushPersistentStorage setReleaseUUID:parameters.releaseUUID];
        [OmniaPushPersistentStorage setReleaseSecret:parameters.releaseSecret];
        [OmniaPushPersistentStorage setDeviceAlias:parameters.deviceAlias];
        
        successBlock(response, parsedData);
    };
    [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:[self omniaPushOperationQueue]
                                                withParameters:parameters
                                                      devToken:devToken
                                                       success:registrationSuccessfulBlock
                                                       failure:failureBlock];
}

+ (OmniaPushAPNSRegistrationRequestOperation *)APNSRegistrationOperationWithParameters:(OmniaPushRegistrationParameters *)parameters
                                                                          successBlock:(void (^)(NSURLResponse *response, id responseObject))successBlock
                                                                          failureBlock:(void (^)(NSURLResponse *response, NSError *error))failureBlock
{
    void (^success)(NSData *devToken) = ^(NSData *devToken) {
        
        if ([self unregistrationRequiredForDevToken:devToken parameters:parameters]) {
            [OmniaPushPersistentStorage setBackEndDeviceID:nil];
            [self sendUnregisterRequestWithParameters:parameters devToken:devToken successBlock:successBlock failureBlock:failureBlock];
            
        } else if([self registrationRequiredForDevToken:devToken parameters:parameters]) {
            [self sendRegisterRequestWithParameters:parameters devToken:devToken successBlock:successBlock failureBlock:failureBlock];
            
        } else {
            successBlock(nil, devToken);
        }
    };
    
    void (^failure)(NSError *error) = ^(NSError *error) {
        failureBlock(nil, error);
    };
    
    OmniaPushAPNSRegistrationRequestOperation *appDelegateOperation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithApplication:[self sharedApplication]
                                                                                             remoteNotificationTypes:parameters.remoteNotificationTypes
                                                                                                             success:success
                                                                                                             failure:failure];
    return appDelegateOperation;
}

+ (UIApplication *)sharedApplication
{
    return [UIApplication sharedApplication];
}

+ (BOOL)unregistrationRequiredForDevToken:(NSData *)devToken
                               parameters:(OmniaPushRegistrationParameters *)parameters
{
    // If not currently registered with the back-end then unregistration is not required
    if (![OmniaPushPersistentStorage APNSDeviceToken]) {
        return NO;
    }
    
    if (![self localdeviceTokenMatchesNewToken:devToken]) {
        return YES;
    }
    
    if (![self localParametersMatchNewParameters:parameters]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)registrationRequiredForDevToken:(NSData *)devToken
                             parameters:(OmniaPushRegistrationParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if (![OmniaPushPersistentStorage backEndDeviceID]) {
        return YES;
    }
    
    if (![self localdeviceTokenMatchesNewToken:devToken]) {
        return YES;
    }
    
    if (![self localParametersMatchNewParameters:parameters]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)localParametersMatchNewParameters:(OmniaPushRegistrationParameters *)parameters
{
    // If any of the registration parameters are different then unregistration is required
    if (![parameters.releaseUUID isEqualToString:[OmniaPushPersistentStorage releaseUUID]]) {
        OmniaPushLog(@"Parameters specify a different releaseUuid. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.releaseSecret isEqualToString:[OmniaPushPersistentStorage releaseSecret]]) {
        OmniaPushLog(@"Parameters specify a different releaseSecret. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.deviceAlias isEqualToString:[OmniaPushPersistentStorage deviceAlias]]) {
        OmniaPushLog(@"Parameters specify a different deviceAlias. Unregistration and re-registration will be required.");
        return NO;
    }
    
    return YES;
}

+ (BOOL)localdeviceTokenMatchesNewToken:(NSData *)devToken {
    if (![devToken isEqualToData:[OmniaPushPersistentStorage APNSDeviceToken]]) {
        OmniaPushLog(@"APNS returned a different APNS token. Unregistration and re-registration will be required.");
        return NO;
    }
    return YES;
}

@end
