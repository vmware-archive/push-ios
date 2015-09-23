//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"
#import "PCFTagsHelper.h"

SPEC_BEGIN(PCFTagsHelperSpec)

describe(@"PCFTagsHelper", ^{
    
    __block PCFTagsHelper *tagsHelper;

    context(@"pcfPushLowercaseTags function", ^{

        it(@"should ignore nil sets", ^{
            [[pcfPushLowercaseTags(nil) should] beNil];
        });

        it(@"should ignore empty sets", ^{
            [[pcfPushLowercaseTags([NSSet<NSString*> set]) should] beEmpty];
        });

        it(@"should lowercase a set with one item", ^{
            [[pcfPushLowercaseTags([NSSet<NSString*> setWithArray:@[ @"UPPER" ]]) should] equal:[NSSet<NSString*> setWithArray:@[ @"upper" ]]];
        });

        it(@"should lowercase a set with some items", ^{
            [[pcfPushLowercaseTags([NSSet<NSString*> setWithArray:@[ @"cATs", @"DogS", @"fish", @"123" ]]) should] equal:[NSSet<NSString*> setWithArray:@[ @"dogs", @"cats", @"123", @"fish" ]]];
        });
    });

    context(@"nil arguments", ^{
        
        it(@"should take a nil list for the saved items", ^{
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:nil newTags:[NSSet<NSString*> set]];
        });
        
        it(@"should take a nil list for the new items", ^{
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:[NSSet<NSString*> set] newTags:nil];
        });

        it(@"should take a nil list for the all items", ^{
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:nil newTags:nil];
        });
        
        afterEach(^{
            [[tagsHelper.subscribeTags should] beEmpty];
            [[tagsHelper.unsubscribeTags should] beEmpty];
        });
    });
    
    it(@"should return empty lists when given empty lists", ^{
        tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:[NSSet<NSString*> set] newTags:[NSSet<NSString*> set]];
        [[tagsHelper.subscribeTags should] beEmpty];
        [[tagsHelper.unsubscribeTags should] beEmpty];
    });
    
    context(@"when the saved tags list is empty", ^{
       
        it(@"should always return when the new tags list", ^{
            
            NSMutableSet<NSString*> *newTags = [NSMutableSet<NSString*> set];
            for (int i = 0; i < 10; i += 1) {
                [newTags addObject:[NSString stringWithFormat:@"%d", i]];
                tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:[NSSet<NSString*> set] newTags:newTags];
                [[tagsHelper.subscribeTags should] equal:newTags];
                [[tagsHelper.unsubscribeTags should] beEmpty];
            }
        });
    });
    
    context(@"mixed nil not-nil arguments", ^{
       
        it(@"should return the saved tags list in the unsubscribe list if the new tags list is nil", ^{
            NSSet<NSString*> *savedTags = [NSSet<NSString*> setWithArray:@[ @1, @2, @3]];
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:savedTags newTags:nil];
            [[tagsHelper.subscribeTags should] beEmpty];
            [[tagsHelper.unsubscribeTags should] equal:savedTags];
        });
        
        it(@"should return the new tags list in the subscribe list if the saved tags list is nil", ^{
            NSSet<NSString*> *newTags = [NSSet<NSString*> setWithArray:@[ @1, @2, @3]];
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:nil newTags:newTags];
            [[tagsHelper.subscribeTags should] equal:newTags];
            [[tagsHelper.unsubscribeTags should] beEmpty];
        });
    });
    
    context(@"when the new tags list is empty", ^{
        
        it(@"should always return the saved tags list in the unsubscribe list", ^{
            
            NSMutableSet<NSString*> *savedTags = [NSMutableSet<NSString*> set];
            for (int i = 0; i < 10; i += 1) {
                [savedTags addObject:[NSString stringWithFormat:@"%d", i]];
                tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:savedTags newTags:[NSSet<NSString*> set]];
                [[tagsHelper.subscribeTags should] beEmpty];
                [[tagsHelper.unsubscribeTags should] equal:savedTags];
            }
        });
    });
    
    context(@"when the contents of the saved and new tags lists are mutually exclusive", ^{
       
        it(@"should unsubscribe from all the old items and subscribe to all the new items", ^{
            
            NSMutableSet<NSString*> *savedTags = [NSMutableSet<NSString*> set];
            for (int i = 0; i < 10; i += 1) {
                [savedTags addObject:[NSString stringWithFormat:@"%d", i]];
                
                NSMutableSet<NSString*> *newTags = [NSMutableSet<NSString*> set];
                for (int j = 10; j < 20; j += 1) {
                    [newTags addObject:[NSString stringWithFormat:@"%d", j]];
                    tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:savedTags newTags:newTags];
                    [[tagsHelper.subscribeTags should] equal:newTags];
                    [[tagsHelper.unsubscribeTags should] equal:savedTags];
                }
            }
        });
    });
    
    context(@"when the contents of the saved and new tags lists are the same", ^{
       
        it(@"should have empty subscribe and unsubscribe lists", ^{
            
            NSMutableSet<NSString*> *tags = [NSMutableSet<NSString*> set];
            for (int i = 0; i < 10; i += 1) {
                [tags addObject:[NSString stringWithFormat:@"%d", i]];
                tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:tags newTags:tags];
                [[tagsHelper.subscribeTags should] beEmpty];
                [[tagsHelper.unsubscribeTags should] beEmpty];
            }
        });
    });
    
    context(@"other scenarios where the lists somewhat overlap", ^{
       
        it(@"overlap scenario 1", ^{
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:[NSSet<NSString*> setWithArray:@[@1, @2, @3]] newTags:[NSSet<NSString*> setWithArray:@[@2, @3, @4]]];
            [[tagsHelper.subscribeTags should] equal:[NSSet<NSString*> setWithArray:@[@4]]];
            [[tagsHelper.unsubscribeTags should] equal:[NSSet<NSString*> setWithArray:@[@1]]];
        });
        
        it(@"overlap scenario 2", ^{
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:[NSSet<NSString*> setWithArray:@[@1, @2]] newTags:[NSSet<NSString*> setWithArray:@[@2, @3, @4]]];
            [[tagsHelper.subscribeTags should] equal:[NSSet<NSString*> setWithArray:@[@3, @4]]];
            [[tagsHelper.unsubscribeTags should] equal:[NSSet<NSString*> setWithArray:@[@1]]];
        });
        
        it(@"overlap scenario 2", ^{
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:[NSSet<NSString*> setWithArray:@[@1, @2, @3]] newTags:[NSSet<NSString*> setWithArray:@[@3, @4]]];
            [[tagsHelper.subscribeTags should] equal:[NSSet<NSString*> setWithArray:@[@4]]];
            [[tagsHelper.unsubscribeTags should] equal:[NSSet<NSString*> setWithArray:@[@1, @2]]];
        });
    });

});

SPEC_END
