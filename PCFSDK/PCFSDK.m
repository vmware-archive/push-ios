//
//  PCFSDK.m
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import "PCFSDK.h"
#import "PCFClient.h"
#import "PCFParameters.h"

@implementation PCFSDK

+ (void)setRegistrationParameters:(PCFParameters *)parameters;
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters may not be nil."];
    }
    
    PCFClient *pushClient = [PCFClient shared];
    pushClient.registrationParameters = parameters;
}

@end
