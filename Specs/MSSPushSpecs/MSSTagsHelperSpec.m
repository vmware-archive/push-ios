//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"
#import "MSSTagsHelper.h"

SPEC_BEGIN(MSSTagsHelperSpec)

describe(@"MSSTagsHelper", ^{
    
    __block MSSTagsHelper *tagsHelper;
    
    context(@"nil arguments", ^{
        
        it(@"should take a nil list for the saved items", ^{
            tagsHelper = [MSSTagsHelper tagsHelperWithSavedTags:nil newTags:@[]];
        });
        
        it(@"should take a nil list for the new items", ^{
            tagsHelper = [MSSTagsHelper tagsHelperWithSavedTags:@[] newTags:nil];
        });

        it(@"should take a nil list for the all items", ^{
            tagsHelper = [MSSTagsHelper tagsHelperWithSavedTags:nil newTags:nil];
        });
        
        afterEach(^{
            [[tagsHelper.subscribeTags should] beEmpty];
            [[tagsHelper.unsubscribeTags should] beEmpty];
        });
    });
    
    it(@"should return empty lists when given empty lists", ^{
        tagsHelper = [MSSTagsHelper tagsHelperWithSavedTags:@[] newTags:@[]];
        [[tagsHelper.subscribeTags should] beEmpty];
        [[tagsHelper.unsubscribeTags should] beEmpty];
    });
    
    context(@"when the saved tags list is empty", ^{
       
        it(@"should always return when the new tags list", ^{
            
            NSMutableArray *newTags = [NSMutableArray array];
            for (int i = 0; i < 10; i += 1) {
                [newTags addObject:[NSString stringWithFormat:@"%d", i]];
                tagsHelper = [MSSTagsHelper tagsHelperWithSavedTags:@[] newTags:newTags];
                [[tagsHelper.subscribeTags should] equal:newTags];
                [[tagsHelper.unsubscribeTags should] beEmpty];
            }
        });
    });
    
    context(@"when the new tags list is empty", ^{
        
        it(@"should always return when the saved tags list", ^{
            
            NSMutableArray *savedTags = [NSMutableArray array];
            for (int i = 0; i < 10; i += 1) {
                [savedTags addObject:[NSString stringWithFormat:@"%d", i]];
                tagsHelper = [MSSTagsHelper tagsHelperWithSavedTags:savedTags newTags:@[]];
                [[tagsHelper.subscribeTags should] beEmpty];
                [[tagsHelper.unsubscribeTags should] equal:savedTags];
            }
        });
    });
    
    context(@"when the contents of the saved and new tags lists are mutually exclusive", ^{
       
        it(@"should unsubscribe from all the old items and subscribe to all the new items", ^{
            
            NSMutableArray *savedTags = [NSMutableArray array];
            for (int i = 0; i < 10; i += 1) {
                [savedTags addObject:[NSString stringWithFormat:@"%d", i]];
                
                NSMutableArray *newTags = [NSMutableArray array];
                for (int j = 10; j < 20; j += 1) {
                    [newTags addObject:[NSString stringWithFormat:@"%d", j]];
                    tagsHelper = [MSSTagsHelper tagsHelperWithSavedTags:savedTags newTags:newTags];
                    [[tagsHelper.subscribeTags should] equal:newTags];
                    [[tagsHelper.unsubscribeTags should] equal:savedTags];
                }
            }
        });
    });
    
    context(@"when the contents of the saved and new tags lists are the same", ^{
       
        it(@"should have empty subscribe and unsubscribe lists", ^{
            
            NSMutableArray *tags = [NSMutableArray array];
            for (int i = 0; i < 10; i += 1) {
                [tags addObject:[NSString stringWithFormat:@"%d", i]];
                tagsHelper = [MSSTagsHelper tagsHelperWithSavedTags:tags newTags:tags];
                [[tagsHelper.subscribeTags should] beEmpty];
                [[tagsHelper.unsubscribeTags should] beEmpty];
            }
        });
    });
    
    context(@"other scenarios where the lists somewhat overlap", ^{
       
        it(@"overlap scenario 1", ^{
            tagsHelper = [MSSTagsHelper tagsHelperWithSavedTags:@[@1, @2, @3] newTags:@[@2, @3, @4]];
            [[tagsHelper.subscribeTags should] equal:@[@4]];
            [[tagsHelper.unsubscribeTags should] equal:@[@1]];
        });
        
        it(@"overlap scenario 2", ^{
            tagsHelper = [MSSTagsHelper tagsHelperWithSavedTags:@[@1, @2] newTags:@[@2, @3, @4]];
            [[tagsHelper.subscribeTags should] equal:@[@3, @4]];
            [[tagsHelper.unsubscribeTags should] equal:@[@1]];
        });
        
        it(@"overlap scenario 2", ^{
            tagsHelper = [MSSTagsHelper tagsHelperWithSavedTags:@[@1, @2, @3] newTags:@[@3, @4]];
            [[tagsHelper.subscribeTags should] equal:@[@4]];
            [[tagsHelper.unsubscribeTags should] equal:@[@1, @2]];
        });
    });

});

SPEC_END
