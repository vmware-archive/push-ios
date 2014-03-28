//
//  CFPushHexUtilSpec.mm
//  CFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"
#import "CFPushHexUtil.h"

#define verifyHexDumpForData(data) [CFPushHexUtil hexDumpForData:(data)]

SPEC_BEGIN(CFPushHexUtilSpec)

describe(@"CFPushHexUtil", ^{

    it(@"should convert nil data", ^{
        [[verifyHexDumpForData(nil) should] beNil];
    });
    
    it(@"should convert empty data", ^{
        [[verifyHexDumpForData([NSData data]) should] equal:@""];
    });
    
    it(@"should convert a string with length 1", ^{
        [[verifyHexDumpForData([@"A" dataUsingEncoding:NSASCIIStringEncoding]) should] equal:@"41"];
    });
    
    it(@"should convert a string with length 2", ^{
        [[verifyHexDumpForData([@"AB" dataUsingEncoding:NSASCIIStringEncoding]) should] equal:@"4142"];
    });
    
    it(@"should convert a string with length 4", ^{
        [[verifyHexDumpForData([@"ABCD" dataUsingEncoding:NSASCIIStringEncoding]) should] equal:@"41424344"];
    });

});

SPEC_END