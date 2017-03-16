//
//  PCFPushSecretUtil.h
//  Pods
//
//  Created by DX202 on 2017-03-06.
//
//

#ifndef PCFPushSecretUtil_h
#define PCFPushSecretUtil_h

#import "PCFPushSecretStorage.h"

@interface PCFPushSecretUtil : NSObject

+ (id<PCFPushSecretStorage>) getStorage;
+ (void)setStorage: (id<PCFPushSecretStorage>)storage;

@end

#endif /* PCFPushSecretUtil_h */
