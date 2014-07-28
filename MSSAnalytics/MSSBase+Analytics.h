//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSBase.h"

@interface MSSBase (Analytics)

+ (BOOL)analyticsEnabled;

+ (void)setAnalyticsEnabled:(BOOL)enabled;

@end
