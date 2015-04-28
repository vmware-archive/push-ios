//
// Created by DX181-XL on 15-04-16.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofencePersistentStore.h"
#import "PCFPushGeofenceDataList.h"
#import "PCFPushDebug.h"
#import "PCFPushGeofenceData.h"
#import "NSObject+PCFJSONizable.h"

@interface PCFPushGeofencePersistentStore ()

@property (nonatomic) NSFileManager *fileManager;

@end

@implementation PCFPushGeofencePersistentStore

- (instancetype) initWithFileManager:(NSFileManager*)fileManager
{
    self = [super init];
    if (self) {
        self.fileManager = fileManager;
    }
    return self;
}

- (PCFPushGeofenceDataList *)currentlyRegisteredGeofences
{
    NSError *error = nil;
    NSArray *possibleURLs = [self.fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    if (!possibleURLs || possibleURLs.count <= 0) {
        PCFPushLog(@"Error getting user library directory.");
        return nil;
    }

    NSString *geofencePath = [possibleURLs[0] stringByAppendingPathComponent:@"PCF_PUSH_GEOFENCE"];
    if (![self.fileManager createDirectoryAtPath:geofencePath withIntermediateDirectories:YES attributes:nil error:&error]) {
        PCFPushLog(@"Error creating directory at path '%@': %@", geofencePath, error);
        return nil;
    }

//    NSString *path = [geofencePath stringByAppendingPathComponent:@"PCF_PUSH_GEOFENCE_50.json"];
//    if (![self.fileManager createFileAtPath:path contents:[NSData data] attributes:nil]) {
//        PCFPushLog(@"Error creating file: %@", path);
//    }

    NSArray *dirContents = [self.fileManager contentsOfDirectoryAtPath:geofencePath error:&error];
    if (!dirContents) {
        PCFPushLog(@"Error reading contents of directory %@: %@", geofencePath, error);
        return nil;
    }

    NSPredicate *filter = [NSPredicate predicateWithFormat:@"lastPathComponent BEGINSWITH 'PCF_PUSH_GEOFENCE_' AND lastPathComponent ENDSWITH '.json'"];
    NSArray *geofenceFiles = [dirContents filteredArrayUsingPredicate:filter];

    PCFPushLog(@"Number of stored geofence files: %d", geofenceFiles.count);

    PCFPushGeofenceDataList *result = [PCFPushGeofenceDataList list];
    for (NSString *geofenceFile in geofenceFiles) {
        NSData *geofenceData = [NSData dataWithContentsOfFile:geofenceFile];
        PCFPushGeofenceData *geofence = [PCFPushGeofenceData pcf_fromJSONData:geofenceData error:&error];
        if (error) {
            PCFPushLog(@"Error reading geofence file '%@': %@", geofenceFile, error);
        } else {
            result[@(geofence.id)] = geofence;
        }
    }

    return result;
}

- (void) reset
{
    // TODO - implement
}

- (void) saveRegisteredGeofences:(PCFPushGeofenceDataList *)geofences
{
    // TODO - implement
}

@end