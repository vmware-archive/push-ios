//
//  OmniaApplicationDelegate.h
//  
//
//  Created by DX123-XL on 2014-03-24.
//
//

#import <Foundation/Foundation.h>

@interface OmniaApplicationDelegate : NSObject <UIApplicationDelegate>

+ (instancetype)omniaApplicationDelegate;

+ (void)resetApplicationDelegate;

- (void)registerWithApplication:(UIApplication *)application
        remoteNotificationTypes:(UIRemoteNotificationType)types
                        success:(void (^)(NSData *devToken))success
                        failure:(void (^)(NSError *error))failure;


@end