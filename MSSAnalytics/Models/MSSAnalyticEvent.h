//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
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
