//
//  PCFPushAnalyticsSpec.m
//  PCFPushPushSpec
//

#import "Kiwi.h"
#import "NSString+Version.h"

SPEC_BEGIN(PCFPushVersionSpec)

    __block void (^testVersionsNewerOrEqual)(NSString*, NSString*) = ^(NSString *olderVersion, NSString *newerVersion) {
        [[theValue([olderVersion isOlderVersionThan:newerVersion]) should] beTrue];
        [[theValue([olderVersion isNewerOrSameVersionThan:newerVersion]) should] beFalse];
    };

    __block void (^testVersionsEqual)(NSString*, NSString*) = ^(NSString *v1, NSString *v2) {
        [[theValue([v1 isNewerOrSameVersionThan:v2]) should] beTrue];
        [[theValue([v2 isNewerOrSameVersionThan:v1]) should] beTrue];
    };

    it(@"1",  ^{ testVersionsNewerOrEqual(@"1.0", @"2.0"); });
    it(@"2",  ^{ testVersionsNewerOrEqual(@"1.0.0.0.0.0", @"2.0"); });
    it(@"3",  ^{ testVersionsNewerOrEqual(@"1 0", @"2 0"); });
    it(@"4",  ^{ testVersionsNewerOrEqual(@"1.0", @"2.0."); });
    it(@"5",  ^{ testVersionsNewerOrEqual(@"1.0", @"1.1.0"); });
    it(@"6",  ^{ testVersionsNewerOrEqual(@"1 0", @"1 1 0"); });
    it(@"7",  ^{ testVersionsNewerOrEqual(@"1.0.1", @"1.0.2"); });
    it(@"8",  ^{ testVersionsNewerOrEqual(@" 1 0 1", @"   1 0.2 "); });
    it(@"9",  ^{ testVersionsNewerOrEqual(@"2.0.0", @"2.0.0.5.4.3.2.1"); });
    it(@"10", ^{ testVersionsNewerOrEqual(@"2.0", @"2.0.0"); });
    it(@"11", ^{ testVersionsNewerOrEqual(@"2.0.0.a", @"2.0.0.b"); });
    it(@"12", ^{ testVersionsNewerOrEqual(@"a", @"b"); });
    it(@"13", ^{ testVersionsNewerOrEqual(@"2.0.0", @"20.0"); });
    it(@"14", ^{ testVersionsNewerOrEqual(@"1.1", @"1.10"); });
    it(@"15", ^{ testVersionsNewerOrEqual(@"1.11", @"1.111"); });
    it(@"16", ^{ testVersionsNewerOrEqual(@"1a", @"10a"); });
    it(@"17", ^{ testVersionsNewerOrEqual(@"10a", @"10a.b"); });
    it(@"18", ^{ testVersionsNewerOrEqual(@"10a", @"10ab"); });
    it(@"19", ^{ testVersionsNewerOrEqual(@"10a.b", @"10ab"); });
    it(@"20", ^{ testVersionsNewerOrEqual(@"1", @"123456"); });
    it(@"21", ^{ testVersionsNewerOrEqual(@"12", @"123456"); });
    it(@"22", ^{ testVersionsNewerOrEqual(@"123", @"123456"); });
    it(@"23", ^{ testVersionsNewerOrEqual(@"1234", @"123456"); });
    it(@"24", ^{ testVersionsNewerOrEqual(@"12345", @"123456"); });
    it(@"25", ^{ testVersionsEqual(@"123456", @"123456"); });
    it(@"26", ^{ testVersionsEqual(@"2", @"2"); });
    it(@"27", ^{ testVersionsNewerOrEqual(@"2", @"2."); }); // Note - this is different than the same case on Android - but we don't think it will ever come up.
    it(@"28", ^{ testVersionsEqual(@"2.0", @"2.0"); });
    it(@"29", ^{ testVersionsEqual(@"2.0.", @"2.0."); });
    it(@"30", ^{ testVersionsEqual(@"2.0.0", @"2.0.0"); });
    it(@"31", ^{ testVersionsNewerOrEqual(@"0", @"1-1-0"); });
    it(@"32", ^{ testVersionsEqual(@"A", @"a"); });
    it(@"33", ^{ testVersionsEqual(@" A", @"a"); });
    it(@"34", ^{ testVersionsEqual(@"A", @" a"); });
    it(@"35", ^{ testVersionsNewerOrEqual(@"1", @"1-1"); });
    it(@"36", ^{ testVersionsNewerOrEqual(@"001", @"2"); });
    it(@"37", ^{ testVersionsNewerOrEqual(@"001", @"02"); });
    it(@"38", ^{ testVersionsNewerOrEqual(@"02", @"005"); });
    it(@"39", ^{ testVersionsNewerOrEqual(@"001", @"002"); });
    it(@"40", ^{ testVersionsNewerOrEqual(@"001", @"20"); });
    it(@"41", ^{ testVersionsNewerOrEqual(@"001", @"020"); });
    it(@"42", ^{ testVersionsNewerOrEqual(@" ", @"1"); });
    it(@"43", ^{ testVersionsNewerOrEqual(@".", @"1"); });
    it(@"44", ^{ testVersionsEqual(@"1.3.3.7", @"1.3.3.7"); });
    it(@"45", ^{ testVersionsNewerOrEqual(@"", @"1"); });
    it(@"46", ^{ testVersionsEqual(@"10a", @"10A"); });
    it(@"47", ^{ testVersionsEqual(@"10AB", @"10ab"); });
    it(@"48", ^{ testVersionsNewerOrEqual(@"10A.B", @"10ab"); });

SPEC_END