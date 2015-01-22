//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PCFAppDelegate;
@class PCFPushParameters;

@interface PCFPushClient : NSObject

@property PCFPushParameters *registrationParameters;

+ (instancetype)shared;
+ (void)resetSharedClient;

- (void)registerWithPCFPushWithDeviceToken:(NSData *)deviceToken
                                   success:(void (^)(void))successBlock
                                   failure:(void (^)(NSError *))failureBlock;

- (void)unregisterForRemoteNotificationsWithSuccess:(void (^)(void))success
                                            failure:(void (^)(NSError *error))failure;
- (void) subscribeToTags:(NSSet *)tags deviceToken:(NSData *)deviceToken deviceUuid:(NSString *)deviceUuid success:(void (^)(void))success failure:(void (^)(NSError*))failure;

@end
