//
//  DecoupleServiceProtocol.h
//  Pods
//
//  Created by zitao0206 on 2024/2/13
//


#import <Foundation/Foundation.h>
@protocol DecoupleServiceProtocol <NSObject>

@optional

+ (BOOL)singleton;

+ (id)shareInstance;

@end
