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
    
    UIBarButtonItem *registerButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(registerButtonPressed)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed)];
    UIBarButtonItem *trashButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashButtonPressed)];

    self.navigationController.toolbarHidden = NO;
    [self setToolbarItems:@[registerButton, flexibleSpace, saveButton, flexibleSpace, trashButton] animated:NO];
    
    [self addLogItem:@"Press the \"Play\" button below to register the device for push notifications." timestamp:[NSDate date]];
    [self addLogItem:@"Press the \"Save\" button below to copy the log to the clipboard." timestamp:[NSDate date]];
    [self addLogItem:@"Press the \"Trash\" button below to clear the log contents." timestamp:[NSDate date]];
}

- (void) registerButtonPressed
{
    [self updateCurrentBaseRowColour];
    [self resetSDK];
    [self initializeSDK];
}

- (void) saveButtonPressed
{
    [self copyEntireLog];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Copied entire log to clipboard."
                                                    message:nil
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void) copyEntireLog
{
    NSMutableString *s = [NSMutableString string];
    for (LogItem *logItem in self.logItems) {
        [s appendString:[NSString stringWithFormat:@"%@\t%@\n", logItem.timestamp, logItem.message]];
    }
    [self copyStringToPasteboard:s];
}

- (void) copyStringToPasteboard:(NSString*)s
{
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    pb.persistent = YES;
    [pb setString:s];
}

- (void) trashButtonPressed
{
    self.logItems = [NSMutableArray array];
    [self.tableView reloadData];
}

- (void) resetSDK
{
    SEL setSharedInstanceSelector = sel_registerName("setSharedInstance:");
    [OmniaPushSDK performSelector:setSharedInstanceSelector withObject:nil];
}

- (void) updateCurrentBaseRowColour
{
    [LogItem updateBaseColour];
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
}

- (void) addLogItem:(NSString*)message timestamp:(NSDate*)timestamp {
    if (!self.logItems) {
        self.logItems = [NSMutableArray array];
    }
    LogItem *logItem = [[LogItem alloc] initWithMessage:message timestamp:timestamp];
    [self.logItems addObject:logItem];
    [self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(self.logItems.count-1) inSection:0]  atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void) initializeSDK {
    [self addLogItem:@"Initializing library." timestamp:[NSDate date]];
    OmniaPushRegistrationParameters *parameters = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:UIRemoteNotificationTypeBadge releaseUuid:RELEASE_UUID releaseSecret:RELEASE_SECRET deviceAlias:DEVICE_ALIAS];
    [OmniaPushSDK registerWithParameters:parameters listener:self];
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
    cell.userInteractionEnabled = NO;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    LogItem *logItem = (LogItem*) self.logItems[indexPath.row];
    [cell setLogItem:logItem containerSize:self.view.frame.size];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    LogItem *item = self.logItems[indexPath.row];
    CGFloat height = [LogItemCell heightForCellWithText:item.message containerSize:self.view.frame.size];
    return height;
}

#pragma mark - OmniaPushRegistrationListener callbacks

- (void) registrationSucceeded
{
    OmniaPushLog(@"Application received callback \"registrationSucceeded\".");
}

- (void) registrationFailedWithError:(NSError*)error
{
    OmniaPushLog(@"Application received callback \"registrationFailedWithError:\". Error: \"%@\"", error.localizedDescription);
}

@end
