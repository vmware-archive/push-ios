//
// Created by DX181-XL on 15-04-16.
//

#import "PCFPushGeofenceDataList+Loaders.h"
#import "PCFPushGeofenceData.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushDebug.h"

NSData* loadTestFile(Class testProjectClass, NSString *name)
{
    NSError *error;
    NSString *filePath = [[NSBundle bundleForClass:testProjectClass] pathForResource:name ofType:@"json"];
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        PCFPushCriticalLog(@"Error reading test file contents '%@': %@", filePath, error);
        return nil;
    }
    return [fileContents dataUsingEncoding:NSUTF8StringEncoding];
}

PCFPushGeofenceDataList* loadGeofenceList(Class testProjectClass, NSString *name)
{
    NSData *data = loadTestFile(testProjectClass, name);
    PCFPushGeofenceDataList *result = [PCFPushGeofenceDataList listFromData:data];
    return result;
};

@implementation PCFPushGeofenceDataList (Loaders)

+ (PCFPushGeofenceDataList *)listFromData:(NSData *)data
{
    if (data == nil) {
        return nil;
    }

    PCFPushGeofenceDataList *list = [PCFPushGeofenceDataList list];
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
        PCFPushGeofenceData *geofence = [PCFPushGeofenceData pcfPushFromDictionary:i];
        resultDict[@(geofence.id)] = geofence;
    }
    return resultDict;
}


@end