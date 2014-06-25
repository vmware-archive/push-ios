//
//  PMSSAppDelegate.h
//  
//
//  Created by DX123-XL on 2014-03-24.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PMSSAppDelegate : NSObject <UIApplicationDelegate>

- (void)setPushRegistrationBlockWithSuccess:(void (^)(NSData *deviceToken))success
                                    failure:(void (^)(NSError *error))failure;
@end
