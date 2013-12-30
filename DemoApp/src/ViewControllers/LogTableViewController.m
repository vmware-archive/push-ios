//
//  LogTableViewController.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-17.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "LogTableViewController.h"
#import "OmniaPushAPNSRegistrationRequestImpl.h"
#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaPushSDKInstance.h"
#import "OmniaPushDebug.h"
#import "LogItem.h"
#import "LogItemCell.h"

@interface LogTableViewController ()

@property (nonatomic) NSMutableArray *logItems;
@property (nonatomic) OmniaPushSDKInstance *sdk;

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
        [self addLogItem:message timestamp:timestamp];
    }];
    
    [self initializeSDK];
}

- (void) addLogItem:(NSString*)message timestamp:(NSDate*)timestamp {
    // TODO - may need a version of this method that can get called from a background thread safely
    if (!self.logItems) {
        self.logItems = [NSMutableArray array];
    }
    LogItem *logItem = [[LogItem alloc] initWithMessage:message timestamp:timestamp];
    [self.logItems addObject:logItem];
    [self.tableView reloadData];
}

- (void) initializeSDK {
    [self addLogItem:@"Initializing library..." timestamp:[NSDate date]];
    // TODO - encapsulate all this stuff in an static wrapper method in the framework itself
    NSObject<OmniaPushAPNSRegistrationRequest> *registrationRequest = [[OmniaPushAPNSRegistrationRequestImpl alloc] init];
    NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:[UIApplication sharedApplication].delegate registrationRequest:registrationRequest];
    self.sdk = [[OmniaPushSDKInstance alloc] initWithApplication:[UIApplication sharedApplication] registrationRequest:registrationRequest appDelegateProxy:appDelegateProxy];
    [self.sdk registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeAlert];
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
