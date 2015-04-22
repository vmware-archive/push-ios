//
// Created by DX181-XL on 15-04-16.
//

#import "PCFPushGeofenceDataList+Loaders.h"
#import "PCFPushGeofenceData.h"
#import "NSObject+PCFJSONizable.h"

PCFPushGeofenceDataList* loadGeofenceList(Class testProjectClass, NSString *name)
{
    NSString *filePath = [[NSBundle bundleForClass:testProjectClass] pathForResource:name ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    PCFPushGeofenceDataList *result = [PCFPushGeofenceDataList listFromData:data];
    return result;
};

@implementation PCFPushGeofenceDataList (Loaders)

+ (PCFPushGeofenceDataList *)listFromData:(NSData *)data
{
    if (data == nil) {
        return nil;
    }

    PCFPushGeofenceDataList *list = [[PCFPushGeofenceDataList alloc] init];
    NSMutableDictionary *loadedDict = [PCFPushGeofenceDataList loadData:data];
    [list addEntriesFromDictionary:loadedDict];

    return list;
}

+ (NSMutableDictionary *) loadData:(NSData *)data
{
    if (!data) {
        return nil;
    }

    if ([data length] <= 0) {
        return [NSMutableDictionary dictionary];
    }

    NSError *error;
    id list = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        @throw [NSException exceptionWithName:NSInvalidArchiveOperationException reason:@"unable to parse serialized geofence list" userInfo:error.userInfo];
    }
    if (![list isKindOfClass:[NSArray class]]) {
        @throw [NSException exceptionWithName:NSInvalidArchiveOperationException reason:@"expected serialized geofence list to be an array" userInfo:nil];
    }

    NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithCapacity:[list count]];
    for (id i in list) {
        if (![i isKindOfClass:[NSDictionary class]]) {
            @throw [NSException exceptionWithName:NSInvalidArchiveOperationException reason:@"expected serialized geofence list item to be a dictionary" userInfo:nil];
        }
        PCFPushGeofenceData *geofence = [PCFPushGeofenceData pcf_fromDictionary:i];
        resultDict[@(geofence.id)] = geofence;
    }
    return resultDict;
}


@end