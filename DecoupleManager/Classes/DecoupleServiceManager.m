//
//  DecoupleServiceManager.m
//  Pods
//
//  Created by zitao0206 on 2024/2/13
//

#import "DecoupleServiceManager.h"
#import <objc/runtime.h>
#import "DecoupleServiceManagerProtocol.h"

static const NSString *kService = @"service";
static const NSString *kImpl = @"impl";

@interface DecoupleServiceManager()

@property (nonatomic, strong) NSMutableDictionary *allServicesDict;
@property (nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation DecoupleServiceManager

+ (instancetype)shared
{
    static id shared = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (void)registerLocalServices
{
    NSString *serviceConfigName = @"ServicesConfig";
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:serviceConfigName ofType:@"plist"];
    if (!plistPath) {
        return;
    }
    
    NSArray *serviceList = [[NSArray alloc] initWithContentsOfFile:plistPath];
    if(serviceList.count == 0){
        return;
    }
    
    [self.lock lock];
    for (NSDictionary *dict in serviceList) {
        NSString *protocolKey = [dict objectForKey:@"service"];
        NSString *protocolImplClass = [dict objectForKey:@"impl"];
        if (protocolKey.length > 0 && protocolImplClass.length > 0) {
            [self.allServicesDict addEntriesFromDictionary:@{protocolKey:protocolImplClass}];
        }
    }
    [self.lock unlock];
}

- (void)registerService:(Protocol *)service implClass:(Class)implClass
{
    NSParameterAssert(service != nil);
    NSParameterAssert(implClass != nil);
    
    // Does impClass follow the Protocol protocol?
    if (![implClass conformsToProtocol:service]) {
        if (self.enableException) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ module does not comply with %@ protocol", NSStringFromClass(implClass), NSStringFromProtocol(service)] userInfo:nil];
        }
        return;
    }
    
    // Protocol Has the protocol been registered?
    if ([self checkValidService:service]) {
        if (self.enableException) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ protocol has been registed", NSStringFromProtocol(service)] userInfo:nil];
        }
        return;
    }
    
    NSString *key = NSStringFromProtocol(service);
    NSString *value = NSStringFromClass(implClass);
    
    if (key.length > 0 && value.length > 0) {
        [self.lock lock];
        [self.allServicesDict addEntriesFromDictionary:@{key:value}];
        [self.lock unlock];
    }
    
    
   
}



- (id)createInstanceWithService:(Protocol *)service
{
    id implInstance = nil;
    
    if (![self checkValidService:service]) {
        if (self.enableException) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ protocol does not been registed", NSStringFromProtocol(service)] userInfo:nil];
        }
    }
    
    Class implClass = [self serviceImplClass:service];
    if ([[implClass class] respondsToSelector:@selector(singleton)]) {
        if ([[implClass class] singleton]) {
            if ([[implClass class] respondsToSelector:@selector(shareInstance)])
                implInstance = [[implClass class] shareInstance];
            else
                implInstance = [[implClass alloc] init];
            
            return implInstance;
        }
    }
    
    return [[implClass alloc] init];
}

#pragma mark - private
- (Class)serviceImplClass:(Protocol *)service
{
    NSString *serviceImpl = [[self servicesDict] objectForKey:NSStringFromProtocol(service)];
    if (serviceImpl.length > 0) {
        return NSClassFromString(serviceImpl);
    }
    return nil;
}

- (BOOL)checkValidService:(Protocol *)service
{
    NSString *serviceImpl = [[self servicesDict] objectForKey:NSStringFromProtocol(service)];
    if (serviceImpl.length > 0) {
        return YES;
    }
    return NO;
}

- (NSMutableDictionary *)allServicesDict
{
    if (!_allServicesDict) {
        _allServicesDict = [NSMutableDictionary dictionary];
    }
    return _allServicesDict;
}

- (NSRecursiveLock *)lock
{
    if (!_lock) {
        _lock = [[NSRecursiveLock alloc] init];
    }
    return _lock;
}

- (NSDictionary *)servicesDict
{
    [self.lock lock];
    NSDictionary *dict = [self.allServicesDict copy];
    [self.lock unlock];
    return dict;
}


@end
