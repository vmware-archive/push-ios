//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSSPushRegistrationData.h"

#define kSubscribeTags @"subscribe"
#define kUnsubscribeTags @"unsubscribe"

@interface MSSPushRegistrationPutRequestData : MSSPushRegistrationData

@property NSArray *subscribeTags;
@property NSArray *unsubscribeTags;

@end
