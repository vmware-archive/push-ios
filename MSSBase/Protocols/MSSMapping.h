//
//  MSSMapping.h
//  
//
//  Created by DX123-XL on 2014-03-31.
//
//

#import <Foundation/Foundation.h>

#ifndef MSS_STR_PROP
#define MSS_STR_PROP( prop ) NSStringFromSelector(@selector(prop))
#define MSS_STRUCT_STRING __unsafe_unretained NSString
#endif

@protocol MSSMapping <NSObject>

+ (NSDictionary *)localToRemoteMapping;

@end
