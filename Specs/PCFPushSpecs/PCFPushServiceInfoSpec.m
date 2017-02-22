//
//  PCFPushServiceInfoSpec.m
//  PCFPushSpecs
//
//  Created by DX202 on 2017-02-22.
//
//

#import "Kiwi.h"
#import "PCFPushServiceInfo.h"

SPEC_BEGIN(PCFPushServiceInfoSpec)
    describe(@"initialization", ^{
        it(@"initializes with the right values", ^{
           PCFPushServiceInfo *serviceInfo = [[PCFPushServiceInfo alloc] initWithApi:@"testurl"
                                                                   devPlatformUuid:@"devPlatform"
                                                                 devPlatformSecret:@"devPlatformSecret"
                                                                  prodPlatformUuid:@"prodPlatform"
                                                                prodPlatformSecret:@"prodPlatformSecret"];
            
            [[[serviceInfo pushApiUrl] should] equal:@"testurl"];
            [[[serviceInfo developmentPushPlatformUuid] should] equal:@"devPlatform"];
            [[[serviceInfo developmentPushPlatformSecret] should] equal:@"devPlatformSecret"];
            [[[serviceInfo productionPushPlatformUuid] should] equal:@"prodPlatform"];
            [[[serviceInfo productionPushPlatformSecret] should] equal:@"prodPlatformSecret"];
        });
    });
SPEC_END
