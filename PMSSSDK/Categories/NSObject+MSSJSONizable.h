//
//  NSObject+MSSJsonizable.h
//  
//
//  Created by DX123-XL on 2014-03-31.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (MSSJSONizable)

+ (instancetype)mss_fromJSONData:(NSData *)JSONData error:(NSError **)error;
- (NSData *)mss_toJSONData:(NSError **)error;

+ (instancetype)mss_fromDictionary:(NSDictionary *)dict;
- (id)mss_toFoundationType;

@end
