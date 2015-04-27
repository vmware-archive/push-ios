//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PCFPushParameters;
@class CLLocationManager;
@class PCFPushGeofenceRegistrar;
@class PCFPushGeofencePersistentStore;
@class PCFPushGeofenceEngine;

@interface PCFPushClient : NSObject

@property(nonatomic, strong) PCFPushParameters *registrationParameters;
@property(nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic, strong) PCFPushGeofenceRegistrar *registrar;
@property(nonatomic, strong) PCFPushGeofencePersistentStore *store;
@property(nonatomic, strong) PCFPushGeofenceEngine *engine;

+ (instancetype)shared;
+ (void)resetSharedClient;

- (void)registerWithPCFPushWithDeviceToken:(NSData *)deviceToken
                                   success:(void (^)(void))successBlock
                                   failure:(void (^)(NSError *))failureBlock;

- (void)unregisterForRemoteNotificationsWithSuccess:(void (^)(void))success
                                            failure:(void (^)(NSError *error))failure;

- (void) subscribeToTags:(NSSet *)tags
             deviceToken:(NSData *)deviceToken
              deviceUuid:(NSString *)deviceUuid
                 success:(void (^)(void))success
                 failure:(void (^)(NSError*))failure;

@end
