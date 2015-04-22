//
// Created by DX173-XL on 2015-04-22.
//

#import "PCFPushGeofenceResponseData+Loaders.h"
#import "NSObject+PCFJSONizable.h"

PCFPushGeofenceResponseData* loadResponseData(Class testProjectClass, NSString *name)
{
    NSError *error;
    NSString *filePath = [[NSBundle bundleForClass:testProjectClass] pathForResource:name ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    PCFPushGeofenceResponseData *result = [PCFPushGeofenceResponseData pcf_fromJSONData:data error:&error];
    return result;
};

@implementation PCFPushGeofenceResponseData (Loaders)
@end