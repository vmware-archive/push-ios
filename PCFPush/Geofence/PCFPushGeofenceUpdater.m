//
// Created by DX173-XL on 2015-04-21.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceUpdater.h"
#import "PCFPushGeofenceEngine.h"
#import "PCFPushURLConnection.h"
#import "PCFPushParameters.h"
#import "PCFPushGeofenceResponseData.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushPersistentStorage.h"

@interface PCFPushGeofenceUpdater()

@property (nonatomic) PCFPushGeofenceEngine *engine;

@end

@implementation PCFPushGeofenceUpdater

- (instancetype) initWithGeofenceEngine:(PCFPushGeofenceEngine*)engine
{
    self = [super init];
    if (self) {
        if (engine == nil) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"engine may not be nil" userInfo:nil];
        }
        self.engine = engine;
    }
    return self;
}

- (void) startGeofenceUpdate:(NSDictionary *)userInfo
                   timestamp:(int64_t)timestamp
                     success:(void (^)(void))successBlock
                     failure:(void( ^)(NSError *error))failureBlock
{

    PCFPushParameters *parameters = [PCFPushParameters defaultParameters];

    void (^requestSuccessBlock)(NSURLResponse *, NSData *) = ^(NSURLResponse *response, NSData *data) {

        NSError *error;
        PCFPushGeofenceResponseData *responseData = [PCFPushGeofenceResponseData pcf_fromJSONData:data error:&error];

        if (error) {
            failureBlock(error);
            return;
        }

        [self.engine processResponseData:responseData withTimestamp:timestamp];

        [PCFPushPersistentStorage setLastModifiedTime:responseData.lastModified];

        if (successBlock) {
            successBlock();
        }
    };

    void (^requestFailureBlock)(NSError *) = ^(NSError *error) {

        // TODO - update the GeofenceStatus
        if (failureBlock) {
            failureBlock(error);
        }
    };

    [PCFPushURLConnection geofenceRequestWithParameters:parameters
                                              timestamp:timestamp
                                                success:requestSuccessBlock
                                                failure:requestFailureBlock];
};

@end