//
//  OmniaPushFakeBackEndUnregistrationRequest.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-04.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniaPushBackEndUnregistrationRequest.h"

@interface OmniaPushFakeBackEndUnregistrationRequest : NSObject<OmniaPushBackEndUnregistrationRequest>

- (void)setupForSuccess;
- (void)setupForFailureWithError:(NSError*)error;

@end
