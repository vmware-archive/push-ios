//
//  LogTableViewController.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-17.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "LogTableViewController.h"
#import "OmniaPushSDK.h"
#import "OmniaPushDebug.h"
#import "LogItem.h"
#import "LogItemCell.h"

#define RELEASE_UUID    @"0e98c4aa-786e-4675-b2e3-05e5d040ab38"
#define RELEASE_SECRET  @"5f2009b5-bb6a-4963-8abf-a18a2162929b"
#define DEVICE_ALIAS    @"Karijini iPod Touch"

@interface LogTableViewController ()

@property (nonatomic) NSMutableArray *logItems;

@end

@implementation LogTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    // Setup cells for loading into table view
    UINib *nib = [UINib nibWithNibName:LOG_ITEM_CELL bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:LOG_ITEM_CELL];
    
    // Don't let the view appear under the status bar
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    [OmniaPushDebug setLogListener:^(NSString *message, NSDate *timestamp) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self addLogItem:message timestamp:timestamp];
        }];
    }];
    
    [self initializeSDK];
}

- (void) addLogItem:(NSString*)message timestamp:(NSDate*)timestamp {
    if (!self.logItems) {
        self.logItems = [NSMutableArray array];
    }
    LogItem *logItem = [[LogItem alloc] initWithMessage:message timestamp:timestamp];
    [self.logItems addObject:logItem];
    [self.tableView reloadData];
}

- (void) initializeSDK {
    [self addLogItem:@"Initializing library." timestamp:[NSDate date]];
    OmniaPushRegistrationParameters *parameters = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:UIRemoteNotificationTypeBadge releaseUuid:RELEASE_UUID releaseSecret:RELEASE_SECRET deviceAlias:DEVICE_ALIAS];
    [OmniaPushSDK registerWithParameters:parameters];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.logItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LogItemCell *cell = [tableView dequeueReusableCellWithIdentifier:LOG_ITEM_CELL forIndexPath:indexPath];
    LogItem *logItem = (LogItem*) self.logItems[indexPath.row];
    [cell setLogItem:logItem containerSize:self.view.frame.size];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    LogItem *item = self.logItems[indexPath.row];
    CGFloat height = [LogItemCell heightForCellWithText:item.message containerSize:self.view.frame.size];
    return height;
}

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
