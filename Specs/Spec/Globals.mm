//
//  Globals.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Cedar-iOS/Cedar-iOS.h>

#import "OmniaPushDebug.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface Globals : NSObject
@end

@implementation Globals

+ (void) beforeEach
{
    [OmniaPushDebug disableLogging:YES];
}

@end
