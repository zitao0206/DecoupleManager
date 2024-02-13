//
//  DecoupleServiceManager.h
//  Pods
//
//  Created by zitao0206 on 2024/2/13
//

#import <Foundation/Foundation.h>

#define DEServiceIMP(ServiceName,Protocol) \
id<Protocol> ServiceName = [[DecoupleServiceManager shared] createInstanceWithService:@protocol(Protocol)]

#define DEService(Protocol) \
(id<Protocol>)[[DecoupleServiceManager shared] createInstanceWithService:@protocol(Protocol)]

#define DEServiceRegister(Protocol,serviceClass) \
[[DecoupleServiceManager shared] registerService:@protocol(Protocol) implClass:serviceClass]

@interface DecoupleServiceManager : NSObject

@property (nonatomic, assign) BOOL  enableException;

+ (instancetype)shared;

//register
- (void)registerLocalServices;

- (void)registerService:(Protocol *)service implClass:(Class)implClass;

//obtain
- (id)createInstanceWithService:(Protocol *)service;

@end

