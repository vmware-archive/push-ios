//
//  PCFAnalyticEvent.h
//  
//
//  Created by DX123-XL on 2014-03-28.
//
//

#import <CoreData/CoreData.h>

OBJC_EXTERN const struct AnalyticEventAttributes {
	__unsafe_unretained NSString *canBuy;
} AnalyticEventAttributes;


@interface PCFAnalyticEvent : NSManagedObject

@end
