//
//  MSSPersistentStorage+Analytics.h
//  
//
//  Created by DX123-XL on 2014-04-25.
//
//

#import "MSSPersistentStorage.h"

@interface MSSPersistentStorage (Analytics)

+ (void)setAnalyticsEnabled:(BOOL)enabled;

+ (BOOL)analyticsEnabled;

@end
