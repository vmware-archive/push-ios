//
//  Copyright (C) 2017 Pivotal Software, Inc. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface PCFPushServiceInfo : NSObject

@property NSString *pushApiUrl;
@property NSString *developmentPushPlatformUuid;
@property NSString *developmentPushPlatformSecret;
@property NSString *productionPushPlatformUuid;
@property NSString *productionPushPlatformSecret;

- (id) initWithApi:(NSString *)apiUrl
   devPlatformUuid:(NSString *)devPlatformUuid
 devPlatformSecret:(NSString *)devPlatformSecret
  prodPlatformUuid:(NSString *)prodPlatformUuid
prodPlatformSecret:(NSString *)prodPlatformSecret;

@end
