//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "MSSClassPropertyUtility.h"

@implementation MSSClassPropertyUtility

static NSString *getPropertyType(objc_property_t property)
{
    const char *type = property_getAttributes(property);
    NSString *typeString = [NSString stringWithUTF8String:type];
    NSArray *attributes = [typeString componentsSeparatedByString:@","];
    NSString *typeAttribute = [attributes objectAtIndex:0];
    
    if ([typeAttribute hasPrefix:@"T@"] && [typeAttribute length] > 1) {
        return [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length]-4)];
    } else {
        return [typeAttribute substringFromIndex:1];
    }
}


+ (NSDictionary *)propertiesForClass:(Class)klass
{
    if (klass == NULL) {
        return nil;
    }
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(klass, &outCount);
    NSMutableDictionary *results = [[NSMutableDictionary alloc] initWithCapacity:outCount];
    
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        
        if (propName) {
            NSString *propertyName = [NSString stringWithCString:propName encoding:[NSString defaultCStringEncoding]];
            NSString *propertyType = getPropertyType(property);
            [results setObject:propertyType forKey:propertyName];
        }
    }
    free(properties);
    
    return [NSDictionary dictionaryWithDictionary:results];
}
@end
