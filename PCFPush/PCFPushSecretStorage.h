//
//  PCFPushSecretStorage.h
//  Pods
//
//  Created by DX202 on 2017-03-06.
//
//

#ifndef PCFPushSecretStorage_h
#define PCFPushSecretStorage_h

@protocol PCFPushSecretStorage
- (void)setRequestHeaders:(NSDictionary *)requestHeaders;
- (NSDictionary *)requestHeaders;
@end

#endif /* PCFPushSecretStorage_h */
