//
//  PMSSMapping.h
//  
//
//  Created by DX123-XL on 2014-03-31.
//
//

#import <Foundation/Foundation.h>

#ifndef PMSS_STR_PROP
#define PMSS_STR_PROP( prop ) NSStringFromSelector(@selector(prop))
#define PMSS_STRUCT_STRING __unsafe_unretained NSString
#endif

@protocol PMSSMapping <NSObject>

+ (NSDictionary *)localToRemoteMapping;

@end
