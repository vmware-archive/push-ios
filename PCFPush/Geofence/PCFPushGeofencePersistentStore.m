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

- (id)objectForKeyedSubscript:(id <NSCopying>)key
{
    return [self geofenceWithId:[(NSNumber*)key longLongValue]];
}

- (PCFPushGeofenceData *)geofenceWithId:(int64_t)id
{
    NSString *geofencesPath = self.geofencesPath;
    if (!geofencesPath) {
        return nil;
    }

    NSString *geofenceFilename = [self filenameForGeofenceId:id atPath:geofencesPath];

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:geofenceFilename options:0 error:&error];
    if (!data) {
        PCFPushLog(@"Error reading geofence file '%@': %@", geofenceFilename, error);
        return nil;
    }

    PCFPushGeofenceData *geofence = [PCFPushGeofenceData pcfPushFromJSONData:data error:&error];
    if (!geofence) {
        PCFPushLog(@"Error deserializing geofence data in file '%@': %@", geofenceFilename, error);
        return nil;
    }

    return geofence;
}

- (PCFPushGeofenceDataList *)currentlyRegisteredGeofences
{
    NSString *geofencesPath = self.geofencesPath;
    if (!geofencesPath) {
        return nil;
    }

    if (![self doesGeofencesDirectoryExist:geofencesPath]) {
        return nil;
    }

    NSArray *filenames = [self geofenceFilenamesAtPath:geofencesPath];
    if (!filenames) {
        return nil;
    }

    // Load all the files in the list
    NSError *error = nil;
    PCFPushGeofenceDataList *result = [PCFPushGeofenceDataList list];
    for (NSString *filename in filenames) {
        NSData *geofenceData = [NSData dataWithContentsOfFile:filename];
        PCFPushGeofenceData *geofence = [PCFPushGeofenceData pcfPushFromJSONData:geofenceData error:&error];
        if (error) {
            PCFPushLog(@"Error reading geofence file '%@': %@", filename, error);
        } else {
            result[@(geofence.id)] = geofence;
        }
    }

    PCFPushLog(@"Number of stored geofence files: %d", filenames.count);

    return result;
}

- (void) reset
{
    NSString *geofencesPath = [self geofencesPath];
    if (!geofencesPath) {
        return;
    }

    if (![self doesGeofencesDirectoryExist:geofencesPath]) {
        return;
    }

    NSArray *filenames = [self geofenceFilenamesAtPath:geofencesPath];
    if (!filenames) {
        return;
    }

    // Delete all files in the list
    [self deleteFiles:filenames];

    PCFPushLog(@"Number of stored geofence files: 0");
}

- (void) saveRegisteredGeofences:(PCFPushGeofenceDataList *)geofences
{
    if (!geofences) {
        return;
    }

    NSString *geofencesPath = self.geofencesPath;
    if (!geofencesPath) {
        return;
    }

    if (![self createGeofenceDirectoryAtPath:geofencesPath]) {
        return;
    }

    NSArray *filenames = [self geofenceFilenamesAtPath:geofencesPath];
    if (!filenames) {
        return;
    }
    NSMutableSet *filenamesToDelete = [NSMutableSet setWithArray:filenames];

    // Write updated geofences
    __block NSError *error = nil;
    [geofences enumerateKeysAndObjectsUsingBlock:^(int64_t id, PCFPushGeofenceData *geofence, BOOL *stop) {
        NSData *data = [geofence pcfPushToJSONData:&error];
        if (error) {
            PCFPushLog(@"Error serializing geofence data for item with ID %lld: ", id, error);
        } else {
            NSString *filename = [self filenameForGeofence:geofence atPath:geofencesPath];
            [self.fileManager createFileAtPath:filename contents:data attributes:nil];
            [filenamesToDelete removeObject:filename];
        }
    }];

    // Delete pre-existing geofences that did not get updated
    [self deleteFiles:filenamesToDelete];

    PCFPushLog(@"Number of stored geofence files: %d", geofences.count);
}

- (NSString*) geofencesPath
{
    NSArray *possibleURLs = [self.fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    if (!possibleURLs || possibleURLs.count <= 0) {
        PCFPushLog(@"Error getting user library directory.");
        return nil;
    }

    NSURL* url = possibleURLs[0];
    NSString *geofencesPath = [url.path stringByAppendingPathComponent:@"PCF_PUSH_GEOFENCE"];
    return geofencesPath;
}

- (BOOL) doesGeofencesDirectoryExist:(NSString*)path
{
    BOOL isDirectory = NO;
    if (![self.fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
        PCFPushLog(@"Note: Geofences directory '%@' does not exist", path);
        return NO;
    }
    if (!isDirectory) {
        PCFPushLog(@"Warning: '%@' is not a directory", path);
        return NO;
    }
    return YES;
}

- (NSArray*) geofenceFilenamesAtPath:(NSString*)path
{
    NSError *error = nil;
    NSArray *urls = [self.fileManager contentsOfDirectoryAtPath:path error:&error];
    if (!urls) {
        PCFPushLog(@"Error reading contents of directory %@: %@", path, error);
        return nil;
    }

    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self BEGINSWITH 'PCF_PUSH_GEOFENCE_' AND self ENDSWITH '.json'"];
    NSArray *filteredFilenames = [urls filteredArrayUsingPredicate:filter];

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:filteredFilenames.count];
    for (NSString *filteredFilename in filteredFilenames) {
        [result addObject:[path stringByAppendingPathComponent:filteredFilename]];
    }
    return result;
}

- (BOOL) createGeofenceDirectoryAtPath:(NSString*)path
{
    NSError *error = nil;
    if (![self.fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
        PCFPushLog(@"Error creating directory at path '%@': %@", path, error);
        return NO;
    }
    return YES;
}

- (NSString*) filenameForGeofence:(PCFPushGeofenceData *)geofenceData atPath:(NSString *)path
{
    return [self filenameForGeofenceId:geofenceData.id atPath:path];
}

- (NSString*) filenameForGeofenceId:(int64_t)id atPath:(NSString *)path
{
    NSString *filename = [NSString stringWithFormat:@"PCF_PUSH_GEOFENCE_%lld.json", id];
    NSString *pathAndFilename = [path stringByAppendingPathComponent:filename];
    return pathAndFilename;
}

- (void) deleteFiles:(NSObject<NSFastEnumeration>*)filenames
{
    NSError *error = nil;
    for (NSString *filename in filenames) {
        if (![self.fileManager removeItemAtPath:filename error:&error]) {
            PCFPushLog(@"Error removing geofence file '%@' : '%@", filename, error);
        }
    }
}

@end
