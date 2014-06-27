//
//  MSSSDK.m
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import "MSSSDK.h"
#import "MSSClient.h"
#import "MSSParameters.h"

@implementation MSSSDK

+ (void)setRegistrationParameters:(MSSParameters *)parameters;
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters may not be nil."];
    }
    
    MSSClient *pushClient = [MSSClient shared];
    pushClient.registrationParameters = parameters;
}

@end
