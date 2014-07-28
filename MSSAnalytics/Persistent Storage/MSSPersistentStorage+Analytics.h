//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSPersistentStorage.h"

@interface MSSPersistentStorage (Analytics)

+ (void)setAnalyticsEnabled:(BOOL)enabled;

+ (BOOL)analyticsEnabled;

@end
