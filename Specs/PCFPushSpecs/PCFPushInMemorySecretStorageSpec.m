//
//  PCFPushInMemorySecretStorageSpec.m
//  PCFPushSpecs
//
//  Created by DX202 on 2017-03-08.
//
//

#import "Kiwi.h"
#import "PCFPushInMemorySecretStorage.h"

SPEC_BEGIN(PCFPushInMemorySecretStorageSpec)
    it(@"initilizes with empty headers", ^{
        PCFPushInMemorySecretStorage *storage = [[PCFPushInMemorySecretStorage alloc] init];
        [[[storage requestHeaders] should] beNil];
    });

    it(@"saves headers", ^{
        PCFPushInMemorySecretStorage *storage = [[PCFPushInMemorySecretStorage alloc] init];
        NSDictionary *headers = @{ @"city"     : @"toronto",
                                   @"latitude" : @"12.12",
                                   };
        [storage setRequestHeaders:headers];
        
        [[[storage requestHeaders] shouldNot] beNil];
        [[[[storage requestHeaders] valueForKeyPath:@"city"] should] equal:@"toronto"];
        [[[[storage requestHeaders] valueForKeyPath:@"latitude"] should] equal:@"12.12"];
    });

    it(@"keeps each copy separate", ^{
        PCFPushInMemorySecretStorage *storage = [[PCFPushInMemorySecretStorage alloc] init];
        NSDictionary *headers = @{ @"city"     : @"toronto",
                                   @"latitude" : @"12.12",
                                   };
        [storage setRequestHeaders:headers];
        
        PCFPushInMemorySecretStorage *otherStorage = [[PCFPushInMemorySecretStorage alloc] init];
        [[[otherStorage requestHeaders] should] beNil];
    });
SPEC_END
