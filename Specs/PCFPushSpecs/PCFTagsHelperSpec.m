//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"
#import "PCFTagsHelper.h"

SPEC_BEGIN(PCFTagsHelperSpec)

describe(@"PCFTagsHelper", ^{
    
    __block PCFTagsHelper *tagsHelper;
    
    context(@"nil arguments", ^{
        
        it(@"should take a nil list for the saved items", ^{
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:nil newTags:[NSSet set]];
        });
        
        it(@"should take a nil list for the new items", ^{
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:[NSSet set] newTags:nil];
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
        tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:[NSSet set] newTags:[NSSet set]];
        [[tagsHelper.subscribeTags should] beEmpty];
        [[tagsHelper.unsubscribeTags should] beEmpty];
    });
    
    context(@"when the saved tags list is empty", ^{
       
        it(@"should always return when the new tags list", ^{
            
            NSMutableSet *newTags = [NSMutableSet set];
            for (int i = 0; i < 10; i += 1) {
                [newTags addObject:[NSString stringWithFormat:@"%d", i]];
                tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:[NSSet set] newTags:newTags];
                [[tagsHelper.subscribeTags should] equal:newTags];
                [[tagsHelper.unsubscribeTags should] beEmpty];
            }
        });
    });
    
    context(@"mixed nil not-nil arguments", ^{
       
        it(@"should return the saved tags list in the unsubscribe list if the new tags list is nil", ^{
            NSSet *savedTags = [NSSet setWithArray:@[ @1, @2, @3]];
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:savedTags newTags:nil];
            [[tagsHelper.subscribeTags should] beEmpty];
            [[tagsHelper.unsubscribeTags should] equal:savedTags];
        });
        
        it(@"should return the new tags list in the subscribe list if the saved tags list is nil", ^{
            NSSet *newTags = [NSSet setWithArray:@[ @1, @2, @3]];
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:nil newTags:newTags];
            [[tagsHelper.subscribeTags should] equal:newTags];
            [[tagsHelper.unsubscribeTags should] beEmpty];
        });
    });
    
    context(@"when the new tags list is empty", ^{
        
        it(@"should always return the saved tags list in the unsubscribe list", ^{
            
            NSMutableSet *savedTags = [NSMutableSet set];
            for (int i = 0; i < 10; i += 1) {
                [savedTags addObject:[NSString stringWithFormat:@"%d", i]];
                tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:savedTags newTags:[NSSet set]];
                [[tagsHelper.subscribeTags should] beEmpty];
                [[tagsHelper.unsubscribeTags should] equal:savedTags];
            }
        });
    });
    
    context(@"when the contents of the saved and new tags lists are mutually exclusive", ^{
       
        it(@"should unsubscribe from all the old items and subscribe to all the new items", ^{
            
            NSMutableSet *savedTags = [NSMutableSet set];
            for (int i = 0; i < 10; i += 1) {
                [savedTags addObject:[NSString stringWithFormat:@"%d", i]];
                
                NSMutableSet *newTags = [NSMutableSet set];
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
            
            NSMutableSet *tags = [NSMutableSet set];
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
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:[NSSet setWithArray:@[@1, @2, @3]] newTags:[NSSet setWithArray:@[@2, @3, @4]]];
            [[tagsHelper.subscribeTags should] equal:[NSSet setWithArray:@[@4]]];
            [[tagsHelper.unsubscribeTags should] equal:[NSSet setWithArray:@[@1]]];
        });
        
        it(@"overlap scenario 2", ^{
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:[NSSet setWithArray:@[@1, @2]] newTags:[NSSet setWithArray:@[@2, @3, @4]]];
            [[tagsHelper.subscribeTags should] equal:[NSSet setWithArray:@[@3, @4]]];
            [[tagsHelper.unsubscribeTags should] equal:[NSSet setWithArray:@[@1]]];
        });
        
        it(@"overlap scenario 2", ^{
            tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:[NSSet setWithArray:@[@1, @2, @3]] newTags:[NSSet setWithArray:@[@3, @4]]];
            [[tagsHelper.subscribeTags should] equal:[NSSet setWithArray:@[@4]]];
            [[tagsHelper.unsubscribeTags should] equal:[NSSet setWithArray:@[@1, @2]]];
        });
    });

});

SPEC_END
