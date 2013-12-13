//
//  ViewController.m
//  DemoApp
//
//  Created by Rob Szumlakowski on 2013-12-13.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "ViewController.h"
#import "OmniaPushSDK.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    OmniaPushSDK *sdk = [[OmniaPushSDK alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
