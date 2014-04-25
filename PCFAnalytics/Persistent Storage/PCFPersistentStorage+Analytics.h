//
//  PCFPersistentStorage+Analytics.h
//  
//
//  Created by DX123-XL on 2014-04-25.
//
//

#import "PCFPersistentStorage.h"

@interface PCFPersistentStorage (Analytics)

+ (void)setAnalyticsEnabled:(BOOL)enabled;

+ (BOOL)analyticsEnabled;

@end
