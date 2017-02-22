//
//  Copyright (C) 2017 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushServiceInfo.h"

@implementation PCFPushServiceInfo

- (id)initWithApi:(NSString *)apiUrl devPlatformUuid:(NSString *)devPlatformUuid devPlatformSecret:(NSString *)devPlatformSecret prodPlatformUuid:(NSString *)prodPlatformUuid prodPlatformSecret:(NSString *)prodPlatformSecret {
    self = [super init];
    if (self) {
        self.pushApiUrl = apiUrl;
        self.developmentPushPlatformUuid = devPlatformUuid;
        self.developmentPushPlatformSecret = devPlatformSecret;
        self.productionPushPlatformUuid = prodPlatformUuid;
        self.productionPushPlatformSecret = prodPlatformSecret;
    }
    
    return self;
}

@end
