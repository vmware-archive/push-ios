//
//  MSSAnalyticEvent.h
//  
//
//  Created by DX123-XL on 2014-03-28.
//
//

#import <CoreData/CoreData.h>
#import "MSSMapping.h"
#import "MSSSortDescriptors.h"

@interface MSSAnalyticEvent : NSManagedObject <MSSMapping, MSSSortDescriptors>

@property (nonatomic, readwrite) NSString *eventType;
@property (nonatomic, readwrite) NSString *eventID;
@property (nonatomic, readwrite) NSString *eventTime;
@property (nonatomic, readwrite) NSDictionary *eventData;

@end
