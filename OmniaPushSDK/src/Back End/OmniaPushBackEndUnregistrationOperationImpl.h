//
//  OmniaPushBackEndUnregistrationRequestImpl.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniaPushBackEndUnregistrationOperationProtocol.h"

@interface OmniaPushBackEndUnregistrationOperation : NSOperation <OmniaPushBackEndUnregistrationOperation, NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@end
