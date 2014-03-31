//
//  PCFPushMapping.h
//  
//
//  Created by DX123-XL on 2014-03-31.
//
//

#import <Foundation/Foundation.h>

#ifndef PCF_STR_PROP
#define PCF_STR_PROP( prop ) NSStringFromSelector(@selector(prop))
#define PCF_STRUCT_STRING __unsafe_unretained NSString
#endif

@protocol PCFPushMapping <NSObject>

+ (NSDictionary *)localToRemoteMapping;

@end
