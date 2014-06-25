//
//  PMSSSDK.m
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import "PMSSSDK.h"
#import "PMSSClient.h"
#import "PMSSParameters.h"

@implementation PMSSSDK

+ (void)setRegistrationParameters:(PMSSParameters *)parameters;
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters may not be nil."];
    }
    
    PMSSClient *pushClient = [PMSSClient shared];
    pushClient.registrationParameters = parameters;
}

@end
