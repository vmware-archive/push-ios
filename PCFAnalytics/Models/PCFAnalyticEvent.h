//
//  PCFAnalyticEvent.h
//  
//
//  Created by DX123-XL on 2014-03-28.
//
//

#import <CoreData/CoreData.h>
#import "PCFMapping.h"
#import "PCFSortDescriptors.h"

@interface PCFAnalyticEvent : NSManagedObject <PCFMapping, PCFSortDescriptors>

@property (nonatomic, readwrite) NSString *eventType;
@property (nonatomic, readwrite) NSString *eventID;
@property (nonatomic, readwrite) NSString *eventTime;
@property (nonatomic, readwrite) NSDictionary *eventData;

@end
