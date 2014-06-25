//
//  NSObject+PMSSJsonizable.h
//  
//
//  Created by DX123-XL on 2014-03-31.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (PMSSJSONizable)

+ (instancetype)pmss_fromJSONData:(NSData *)JSONData error:(NSError **)error;
- (NSData *)pmss_toJSONData:(NSError **)error;

+ (instancetype)pmss_fromDictionary:(NSDictionary *)dict;
- (id)pmss_toFoundationType;

@end
