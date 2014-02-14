//
//  OmniaPushHexUtilSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushHexUtil.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define verifyHexDumpForData(data) [OmniaPushHexUtil hexDumpForData:(data)]

SPEC_BEGIN(OmniaPushHexUtilSpec)

describe(@"OmniaPushHexUtil", ^{

    it(@"should convert nil data", ^{
        verifyHexDumpForData(nil) should be_nil;
    });
    
    it(@"should convert empty data", ^{
        verifyHexDumpForData([NSData data]) should equal(@"");
    });
    
    it(@"should convert a string with length 1", ^{
        verifyHexDumpForData([@"A" dataUsingEncoding:NSASCIIStringEncoding]) should equal(@"41");
    });
    
    it(@"should convert a string with length 2", ^{
        verifyHexDumpForData([@"AB" dataUsingEncoding:NSASCIIStringEncoding]) should equal(@"4142");
    });
    
    it(@"should convert a string with length 4", ^{
        verifyHexDumpForData([@"ABCD" dataUsingEncoding:NSASCIIStringEncoding]) should equal(@"41424344");
    });

});

SPEC_END
