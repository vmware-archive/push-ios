//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSBase.h"
#import "MSSClient.h"
#import "MSSParameters.h"

@implementation MSSBase

+ (void)setRegistrationParameters:(MSSParameters *)parameters;
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters may not be nil."];
    }
    
    MSSClient *pushClient = [MSSClient shared];
    pushClient.registrationParameters = parameters;
}

@end
