//
//  OmniaPushSDK.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "OmniaPushSDK.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushAppDelegateOperation.h"
#import "OmniaPushBackEndUnregistrationOperationProtocol.h"
#import "OmniaPushBackEndUnregistrationOperationImpl.h"
#import "OmniaPushApplicationDelegateSwitcher.h"
#import "OmniaPushApplicationDelegateSwitcherProvider.h"
#import "OmniaPushRegistrationEngine.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaPushDebug.h"

// Global constant storage
NSString *const OmniaPushErrorDomain = @"OmniaPushErrorDomain";

static NSString *deviceID = nil;

@interface OmniaPushSDK ()

@end

@implementation OmniaPushSDK

+ (NSOperationQueue *)omniaPushOperationQueue {
    static NSOperationQueue *workerQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        workerQueue = [[NSOperationQueue alloc] init];
        workerQueue.maxConcurrentOperationCount = 1;
        workerQueue.name = @"OmniaPushOperationQueue";
    });
    return workerQueue;
}

+ (void) registerWithParameters:(OmniaPushRegistrationParameters *)parameters
{
    [self registerWithParameters:parameters success:nil failure:nil];
}

// NOTE:  the application delegate will still be called after APNS registration completes, except if the
// registration attempt times out.  The listener will be called after both APNS registration and registration
// with the back-end Omnia server compeltes of fails.  Time-outs with APNS registration are not detected.  Time-outs
// with the Omnia server are detected after 60 seconds.

+ (void) registerWithParameters:(OmniaPushRegistrationParameters *)parameters
                        success:(void (^)(id responseObject))success
                        failure:(void (^)(NSError *error))failure
{
    if (parameters == nil) {
        [NSException raise:NSInvalidArgumentException format:@"parameters may not be nil"];
    }
    
    NSOperation *unregisterOperation = [[OmniaPushBackEndUnregistrationOperation alloc] initDeviceUnregistrationWithUUID:@""
                                                                                                               onSuccess:^{
        <#code#>
    }
                                                                                                               onFailure:^(NSError *error) {
        <#code#>
    }];
    
    NSOperation *appDelegateOperation = [[OmniaPushAppDelegateOperation alloc] initWithApplication:[self sharedApplication]
                                                                remoteNotificationTypes:parameters.remoteNotificationTypes
                                                                                success:^(NSData *devToken) {
                                                                                    if ([self.class isBackEndUnregistrationRequiredForDevToken:devToken parameters:parameters]) {
                                                                                        [[self omniaPushOperationQueue] addOperation:];
                                                                                        
                                                                                    } else if([self.class isBackEndRegistrationRequiredForDevToken:devToken parameters:parameters]) {
                                                                                        [[self omniaPushOperationQueue] addOperation:];
                                                                                        
                                                                                    }
                                                                                }
                                                                                failure:^(NSError *error) {
                                                                                    failure(error);
                                                                                }];
    [[self omniaPushOperationQueue] addOperation:appDelegateOperation];
}

+ (UIApplication *) sharedApplication
{
    return [UIApplication sharedApplication];
}

+ (BOOL) isBackEndUnregistrationRequiredForDevToken:(NSData *)devToken
                                         parameters:(OmniaPushRegistrationParameters *)parameters
{
    // If not currently registered with the back-end then unregistration is not required
    if (devToken == nil) {
        return NO;
    }
    
    return [self.class newParametersMismatchLocalParametersForDevToken:devToken parameters:parameters];

}

+ (BOOL)isBackEndRegistrationRequiredForDevToken:(NSData *)devToken
                                      parameters:(OmniaPushRegistrationParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if ([OmniaPushPersistentStorage loadBackEndDeviceID] == nil) {
        return YES;
    }
    
    return [self.class newParametersMismatchLocalParametersForDevToken:devToken parameters:parameters];
    
}

+ (BOOL)newParametersMismatchLocalParametersForDevToken:(NSData *)devToken
                                             parameters:(OmniaPushRegistrationParameters *)parameters {
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
