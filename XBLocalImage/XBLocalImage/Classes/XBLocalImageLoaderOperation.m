//
//  XBLocalImageLoaderOperation.m
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import "XBLocalImageLoaderOperation.h"

typedef NSMutableDictionary<NSString *, id> XBCallbacksDictionary;
static NSString *const kCompletedCallbackKey = @"kCompletedCallbackKey";

@interface XBLocalImageLoaderOperation ()

//两个参数在NSOperation中是read only，但是自定义Operation我们需要修改它们的值
@property (nonatomic, assign, getter=isFinished) BOOL finished;
@property (nonatomic, assign, getter=isExecuting) BOOL executing;

@property (nonatomic, strong) NSString *imagePath;

@property (nonatomic, strong) NSMutableArray<XBCallbacksDictionary *> *callbackBlocks;
@property (nonatomic, strong) dispatch_queue_t barrierQueue; //http://stackoverflow.com/questions/8904206/what-property-should-i-use-for-a-dispatch-queue-after-arc
@property (nonatomic, strong) dispatch_queue_t  loaderQueue;

@end

@implementation XBLocalImageLoaderOperation
@synthesize finished = _finished;
@synthesize executing = _executing;

- (instancetype)initWithImagePath:(NSString *)imagePath {
    if (self = [super init]) {
        _imagePath = imagePath;
        _finished = NO;
        _executing = NO;
        _callbackBlocks = [NSMutableArray new];
        _barrierQueue = dispatch_queue_create("com.xiabob.XBLocalImageLoaderOperation.barrierQueue", DISPATCH_QUEUE_CONCURRENT);
        _loaderQueue = dispatch_queue_create("com.xiabob.XBLocalImageLoaderOperation.loaderQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    
    return self;
}


#pragma mark - handle block

- (NSMutableDictionary *)addCompletedBlock:(XBLocalImageLoadCompletedBlock)completeBlock {
    //对于多个视图对同一个path做load，operation只有一个，但保存相应的回调，回调会有多个，这样避免重复请求
    XBCallbacksDictionary *callback = [NSMutableDictionary new];
    callback[kCompletedCallbackKey] = completeBlock;
    dispatch_barrier_sync(self.barrierQueue, ^{
        [self.callbackBlocks addObject:callback];
    });
    
    return callback;
}

- (NSArray *)callbacksForKey:(NSString *)key {
    __block NSMutableArray *callbacks = [NSMutableArray new];
    dispatch_barrier_sync(self.barrierQueue, ^{
        callbacks = [[self.callbackBlocks valueForKey:key] mutableCopy];
        //progress block maybe not set, is nil
        [callbacks removeObjectIdenticalTo:[NSNull null]];
    });
    
    return [callbacks copy];
}

- (NSArray *)completedCallbacks {
    return [self callbacksForKey:kCompletedCallbackKey];
}

- (void)callCompletedBlockWithError:(NSError *)error {
    [self callCompletedBlockWithImage:nil error:error andFinished:YES];
}

- (void)callCompletedBlockWithImage:(UIImage *)image
                              error:(NSError *)error
                        andFinished:(BOOL)finished {
    //注意：如果[self completedCallbacks]放在dispatch_main_async_safe里面，就有可能出问题，clear方法会remove这些block，这样就无法保证操作的原子性。因此取block时，可能block已经被删除了，无法发生回调。
    //    NSArray *blocks = [self completedCallbacks];
    //    dispatch_main_async_safe(^{
    //        for (XBWebImageDownloaderCompletedBlock completedBlock in blocks) {
    //            completedBlock(image, data, error, finished);
    //            NSLog(@"call");
    //        }
    //    });
    
    
    //not main thread
    NSArray *blocks = [self completedCallbacks];
    for (XBLocalImageLoadCompletedBlock completedBlock in blocks) {
        completedBlock(image, error, finished);
    }
}

#pragma mark - Logic

//编程指南：https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html
- (void)start {
    //isReady为NO，start方法不会执行,比如operation有其他dependencies，那么isReady就是NO，正常情况下，你不需要重写isReady，除非自定义的operation中有其他因素会影响isReady的状态
    //operation的执行影响因素：1、isReady；2、queuePriority。isReady都是YES，则优先级高的先执行
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            [self clear];
        }
        
        self.executing = YES;
        
        dispatch_async(self.loaderQueue, ^{
            NSData *imageData = [NSData dataWithContentsOfFile:self.imagePath];
            if (imageData) {
                UIImage *image = [UIImage imageWithData:imageData];
                [self callCompletedBlockWithImage:image error:nil andFinished:YES];
            } else {
                [self callCompletedBlockWithError:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSURLLocalizedNameKey: @"Image path can't be nil"}]];
            }
            [self done];
        });
    }
}

#pragma mark - Operation Status

- (void)setFinished:(BOOL)finished {
    //手动调用kvo，应该是automaticallyNotifiesObserversOfFinished返回的是NO，自动调用被关闭了https://objccn.io/issue-7-3/ ,http://stackoverflow.com/questions/3573236/why-does-nsoperation-disable-automatic-key-value-observing
    [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    _finished = finished;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    _executing = executing;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
}

//isConcurrent To be deprecated; use and override 'asynchronous' below
- (BOOL)isAsynchronous {
    //设置同步还是异步，同步情况下不需要reimplement上面两个参数
    return YES;
}

- (BOOL)cancel:(id)callback {
    //回调可能有多个，只有当所有回调被清除，表明所有的请求被取消了
    __block BOOL shouldCancel = NO;
    dispatch_barrier_sync(self.barrierQueue, ^{
        [self.callbackBlocks removeObject:callback];
        if (self.callbackBlocks.count == 0) {
            shouldCancel = YES;
        }
    });
    if (shouldCancel) {
        [self cancel];
    }
    
    return shouldCancel;
}

- (void)cancel {
    @synchronized (self) {
        [self cancelInternal];
    }
}

- (void)cancelInternal {
    if (self.isFinished) {return;}
    [super cancel];
    
    if (self.isExecuting) {self.executing = NO;}
    if (!self.isFinished) {self.finished = YES;}
    
    [self clear];
}

- (void)done {
    self.executing = NO;
    self.finished = YES;
    [self clear];
}

- (void)clear { //清理操作
    dispatch_barrier_async(self.barrierQueue, ^{
        [self.callbackBlocks removeAllObjects];
    });
}

@end
