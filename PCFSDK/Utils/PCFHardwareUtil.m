//
//  PCFPushHardwareUtil.m
//  PCFPushSDK
//
//  Created by DX123-XL on 2014-02-24.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PCFHardwareUtil.h"
#include <sys/types.h>
#include <sys/sysctl.h>

#define STATIC_VARIABLE(VARIABLENAME, VARIABLEVALUE)       \
static NSString *VARIABLENAME;                             \
static dispatch_once_t onceToken;                          \
dispatch_once(&onceToken, ^{                               \
    VARIABLENAME = VARIABLEVALUE;                          \
});                                                        \
return VARIABLENAME;                                       \

@implementation PCFHardwareUtil

+ (NSString *)operatingSystem
{
    STATIC_VARIABLE(operatingSystem, @"ios");
}

+ (NSString *)operatingSystemVersion
{
    STATIC_VARIABLE(operatingSystemVersion, [[UIDevice currentDevice] systemVersion]);
}

+ (NSString *)deviceModel
{
    STATIC_VARIABLE(deviceModel, [PCFHardwareUtil hardwareSimpleDescription]);
}

+ (NSString *)deviceManufacturer
{
    STATIC_VARIABLE(deviceManufacturer, @"Apple");
}

+ (NSString *)hardwareString
{
    size_t size = 100;
    char *hw_machine = malloc(size);
    int name[] = {CTL_HW,HW_MACHINE};
    sysctl(name, 2, hw_machine, &size, NULL, 0);
    NSString *hardware = [NSString stringWithUTF8String:hw_machine];
    free(hw_machine);
    return hardware;
}

+ (NSString *)hardwareSimpleDescription
{
    static NSDictionary *hardwareDescriptionDictionary = nil;
    
    if (!hardwareDescriptionDictionary) {
        hardwareDescriptionDictionary = @{
                                          @"iPhone1,1" : @"iPhone 2G",
                                          @"iPhone1,2" : @"iPhone 3G",
                                          @"iPhone2,1" : @"iPhone 3GS",
                                          @"iPhone3,1" : @"iPhone 4",
                                          @"iPhone3,2" : @"iPhone 4",
                                          @"iPhone3,3" : @"iPhone 4",
                                          @"iPhone4,1" : @"iPhone 4S",
                                          @"iPhone5,1" : @"iPhone 5",
                                          @"iPhone5,2" : @"iPhone 5",
                                          @"iPhone5,3" : @"iPhone 5C",
                                          @"iPhone5,4" : @"iPhone 5C",
                                          @"iPhone6,1" : @"iPhone 5S",
                                          @"iPhone6,2" : @"iPhone 5S",
                                          @"iPod1,1" : @"iPod Touch (1 Gen)",
                                          @"iPod2,1" : @"iPod Touch (2 Gen)",
                                          @"iPod3,1" : @"iPod Touch (3 Gen)",
                                          @"iPod4,1" : @"iPod Touch (4 Gen)",
                                          @"iPod5,1" : @"iPod Touch (5 Gen)",
                                          @"iPad1,1" : @"iPad",
                                          @"iPad1,2" : @"iPad",
                                          @"iPad2,1" : @"iPad 2",
                                          @"iPad2,2" : @"iPad 2",
                                          @"iPad2,3" : @"iPad 2",
                                          @"iPad2,4" : @"iPad 2",
                                          @"iPad2,5" : @"iPad Mini",
                                          @"iPad2,6" : @"iPad Mini",
                                          @"iPad2,7" : @"iPad Mini",
                                          @"iPad3,1" : @"iPad 3",
                                          @"iPad3,2" : @"iPad 3",
                                          @"iPad3,3" : @"iPad 3",
                                          @"iPad3,4" : @"iPad 4",
                                          @"iPad3,5" : @"iPad 4",
                                          @"iPad3,6" : @"iPad 4",
                                          @"iPad4,1" : @"iPad Air",
                                          @"iPad4,2" : @"iPad Air",
                                          @"iPad4,3" : @"iPad Air",
                                          @"iPad4,4" : @"iPad Mini Retina",
                                          @"iPad4,5" : @"iPad Mini Retina",
                                          @"i386" : @"Simulator",
                                          @"x86_64" : @"Simulator",
                                          };
    }
    
    NSString *hardware = [self hardwareString];
    NSString *description = hardwareDescriptionDictionary[hardware];
    
    if (description) {
        return description;
    }
    
    NSLog(@"Your device hardware string is: %@", hardware);
    
    if ([hardware hasPrefix:@"iPhone"]) {
        return @"iPhone";
    }
    if ([hardware hasPrefix:@"iPod"]) {
        return @"iPod";
    }
    if ([hardware hasPrefix:@"iPad"]) {
        return @"iPad";
    }

    return nil;
}

@end
