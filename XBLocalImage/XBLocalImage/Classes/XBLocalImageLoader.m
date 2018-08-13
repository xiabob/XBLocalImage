//
//  XBLocalImageLoader.m
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import "XBLocalImageLoader.h"
#import "XBLocalImageLoaderOperation.h"

@implementation XBLocalImageLoaderToken

@end


@interface XBLocalImageLoader ()

@property (nonatomic, strong) NSOperationQueue *loadOperationQueue;
@property (nonatomic, strong) dispatch_queue_t barrierQueue;
@property (nonatomic, strong) NSMutableDictionary <NSURL *, XBLocalImageLoaderOperation *> *urlOperations;

@end

@implementation XBLocalImageLoader

+ (instancetype)sharedLoader {
    static XBLocalImageLoader *loader;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        loader = [XBLocalImageLoader new];
    });
    
    return loader;
}

- (instancetype)init {
    if (self = [super init]) {
        _loadOperationQueue = [NSOperationQueue new];
        _loadOperationQueue.maxConcurrentOperationCount = 6;
        _loadOperationQueue.name = @"com.xiabob.XBLocalImageLoader";
        _barrierQueue = dispatch_queue_create("com.xiabob.XBLocalImageLoader.barrier", DISPATCH_QUEUE_CONCURRENT);
        _urlOperations = [NSMutableDictionary new];
        _executionOrder = XBLocalImageLoaderExecutionOrderFIFO;
    }
    
    return self;
}

- (void)dealloc {
    [self.loadOperationQueue cancelAllOperations];
}

- (void)setMaxConcurrentLoad:(NSUInteger)maxConcurrentDownload {
    self.loadOperationQueue.maxConcurrentOperationCount = maxConcurrentDownload;
}

- (XBLocalImageLoaderToken *)loadImageWithUrl:(NSURL *)url
                                      options:(XBLocalImageLoaderOptions)options
                                    completed:(XBLocalImageLoadCompletedBlock)completedBlock {
    __block XBLocalImageLoaderToken *token;
    dispatch_barrier_sync(self.barrierQueue, ^{
        XBLocalImageLoaderOperation *operation = self.urlOperations[url];
        if (!operation) { //需要创建
            operation = [[XBLocalImageLoaderOperation alloc] initWithImagePath:url];
            __weak XBLocalImageLoaderOperation *wOperation = operation;
            
            //设置completionBlock，operation完成，移除urlOperations数组中对应的operation。注意，通过kvo，当finished时YES，operationQueue是自动移除对应的operation。这就是为什么自定义operation时，需要重写finished等属性。
            operation.completionBlock = ^{
                __strong typeof(wOperation) sOperation = wOperation;
                if (!sOperation) { return ;}
                if (self.urlOperations[url] == sOperation) {
                    [self.urlOperations removeObjectForKey:url];
                }
            };
            
            //设置queuePriority
            if (options & XBLocalImageLoaderOptionsLowPriority) {
                operation.queuePriority = NSOperationQueuePriorityLow;
            } else if (options & XBLocalImageLoaderOptionsHighPriority) {
                operation.queuePriority = NSOperationQueuePriorityHigh;
            }
            
            //设置execution order
            if (self.executionOrder == XBLocalImageLoaderExecutionOrderFILO) {
                XBLocalImageLoaderOperation *last = [self.loadOperationQueue.operations lastObject];
                [last addDependency:operation];
            }
            
            self.urlOperations[url] = operation;
            [self.loadOperationQueue addOperation:operation];
        }
        
        token = [XBLocalImageLoaderToken new];
        token.url = url;
        token.callback = [operation addCompletedBlock:completedBlock];
    });
    
    return token;
}

- (void)cancel:(XBLocalImageLoaderToken *)token {
    if (!token) {return;}
    dispatch_barrier_async(self.barrierQueue, ^{
        XBLocalImageLoaderOperation *operation = self.urlOperations[token.url];
        if ([operation cancel:token.callback]) {
            [self.urlOperations removeObjectForKey:token.url];
        }
    });
}

- (void)cancelAllOperations {
    [self.loadOperationQueue cancelAllOperations];
}


@end
