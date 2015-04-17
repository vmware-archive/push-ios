//
// Created by DX181-XL on 15-04-16.
//

#import <Foundation/Foundation.h>
#import "PCFPushGeofenceDataList.h"

@interface PCFPushGeofenceDataList (Loaders)

+ (PCFPushGeofenceDataList *)listFromData:(NSData *)data;

@end