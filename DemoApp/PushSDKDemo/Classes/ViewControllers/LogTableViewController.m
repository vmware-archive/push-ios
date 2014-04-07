//
//  LogTableViewController.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-17.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "LogTableViewController.h"
#import "PCFPushParameters.h"
#import "PCFPushSDK.h"
#import "PCFPushDebug.h"
#import "LogItem.h"
#import "LogItemCell.h"
#import "SettingsTableViewController.h"
#import "Settings.h"
#import "BackEndMessageRequest.h"
#import "PCFPushPersistentStorage.h"

static NSString *const APP_UUID       = @"11623d1b-6a80-4a6f-9597-e5d0f320ade9";
static NSString *const APP_SECRET_KEY = @"8c18277b-1b41-453b-b1a2-9f600c9e0d8e";

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
    
    [PCFPushDebug setLogListener:^(NSString *message, NSDate *timestamp) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self addLogItem:message timestamp:timestamp];
        }];
    }];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Copy" style:UIBarButtonItemStylePlain target:self action:@selector(saveButtonPressed)];
    UIBarButtonItem *trashButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashButtonPressed)];
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(sendButtonPressed)];
    UIBarButtonItem *preferencesButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(preferencesButtonPressed)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [self setToolbarItems:@[space, saveButton, space, preferencesButton, space, sendButton, space, trashButton] animated:NO];
    
    [self addLogItem:@"Press the \"Copy\" button below to copy the log to the clipboard." timestamp:[NSDate date]];
    [self addLogItem:@"Press the \"Settings\" button below to change the SDK settings." timestamp:[NSDate date]];
    [self addLogItem:@"Press the \"Play\" button below to send a push message via the back-end server." timestamp:[NSDate date]];
    [self addLogItem:@"Press the \"Trash\" button below to clear the log contents." timestamp:[NSDate date]];
}

- (void) sendButtonPressed
{
    [self updateCurrentBaseRowColour];
    NSString *backEndDeviceID = [PCFPushPersistentStorage pushServerDeviceID];
    
    if (backEndDeviceID == nil) {
        [self addLogItem:@"You must register with the back-end server before attempting to send a message" timestamp:[NSDate date]];
        return;
        
    }
    BackEndMessageRequest *request = [[BackEndMessageRequest alloc] init];
    request.messageTitle = @"Sample Message Title";
    request.messageBody = [NSString stringWithFormat:@"This message was sent to the back-end at %@.", [[LogItem getDateFormatter] stringFromDate:[NSDate date]]];
    request.appUuid = APP_UUID;
    request.appSecretKey = APP_SECRET_KEY;
    request.targetPlatform = @"ios";
    request.targetDevices = @[backEndDeviceID];
    [request sendMessage];
}

- (void) preferencesButtonPressed
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    SettingsTableViewController *settingsTableViewController = (SettingsTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"SettingsTableViewController"];
    [self.navigationController pushViewController:settingsTableViewController animated:YES];
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

- (void) updateCurrentBaseRowColour
{
    [LogItem updateBaseColour];
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
}

- (void) addLogItem:(NSString*)message timestamp:(NSDate*)timestamp
{
    if (!self.logItems) {
        self.logItems = [NSMutableArray array];
    }
    LogItem *logItem = [[LogItem alloc] initWithMessage:message timestamp:timestamp];
    [self.logItems addObject:logItem];
    [self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(self.logItems.count-1) inSection:0]  atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LogItem *item = self.logItems[indexPath.row];
    CGFloat height = [LogItemCell heightForCellWithText:item.message containerSize:self.view.frame.size];
    return height;
}

@end
