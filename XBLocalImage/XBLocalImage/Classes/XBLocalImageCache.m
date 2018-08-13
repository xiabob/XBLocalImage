//
//  XBLocalImageCache.m
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import "XBLocalImageCache.h"
#import "XBLocalImageDecoder.h"

@interface XBLocalImageCache ()

@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSCache *memoryCache;
@property (nonatomic, strong) dispatch_queue_t ioQueue;
@property (nonatomic, strong) XBLocalImageDecoder *decoder;

@end

@implementation XBLocalImageCache

+ (instancetype)sharedCache {
    static XBLocalImageCache *cache;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        cache = [XBLocalImageCache new];
    });
    return cache;
}

- (instancetype)init {
    if (self = [super init]) {
        _lock = [NSLock new];
        _memoryCache = [NSCache new];
        _memoryCache.totalCostLimit = 1024*1024*50;
        _memoryCache.countLimit = 100;
        _ioQueue = dispatch_queue_create("com.xiabob.XBLocalImageCache.io", DISPATCH_QUEUE_CONCURRENT);
        _decoder = [XBLocalImageDecoder new];
        
        [self addNotification];
    }
    
    return self;
}

- (void)dealloc {
    [self removeNotification];
}

- (void)setTotalCostLimit:(NSUInteger)totalCostLimit {
    [self.lock lock];
    _totalCostLimit = totalCostLimit;
    _memoryCache.totalCostLimit = _totalCostLimit;
    [self.lock unlock];
}

- (void)setCountLimit:(NSUInteger)countLimit {
    [self.lock lock];
    _countLimit = countLimit;
    _memoryCache.countLimit = countLimit;
    [self.lock unlock];
}

#pragma mark - cache operation

- (UIImage *)memoryCacheForKey:(NSString *)key {
    [self.lock lock];
    UIImage *image = [self.memoryCache objectForKey:key];
    [self.lock unlock];
    
    return image;
}

- (void)saveImage:(UIImage *)image forKey:(NSString *)key {
    dispatch_async(self.ioQueue, ^{
        [self.lock lock];
        [self saveImgaeToMemory:image forKey:key];
        [self.lock unlock];
    });
}

- (void)saveImgaeToMemory:(UIImage *)image forKey:(NSString *)key {
    if (image) {
        //粗略的计算
        NSUInteger size = image.size.width * image.size.height;
        [self.memoryCache setObject:image forKey:key cost:size];
    }
}

#pragma mark - clear cache

- (void)clearMemoryCache {
    [self.lock lock];
    [self.memoryCache removeAllObjects];
    [self.lock unlock];
}

#pragma mark - notification

- (void)addNotification {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(clearMemoryCache)
                          name:UIApplicationDidReceiveMemoryWarningNotification
                        object:nil];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
