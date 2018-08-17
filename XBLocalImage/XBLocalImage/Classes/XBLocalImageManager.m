//
//  XBLocalImageManager.m
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import "XBLocalImageManager.h"
#import "XBLocalImageCache.h"
#import "XBLocalImageLoaderOperation.h"
#import "XBLocalImageDecoder.h"
#import "XBLocalImageLoader.h"

@interface XBLocalImageContainerOperation : NSOperation

@property (nonatomic, assign, getter=isCancelled) BOOL cancel;
@property (nonatomic, strong) XBLocalImageLoaderToken *token;

@end

@interface XBLocalImageManager ()

@property (nonatomic, strong) XBLocalImageCache *imageCache;
@property (nonatomic, strong) XBLocalImageLoader *imageLoader;
@property (nonatomic, strong) NSMutableArray *operationContainers;
@property (nonatomic, strong) dispatch_queue_t loadQueue;
@property (nonatomic, strong) XBLocalImageDecoder *decoder;

@end

@implementation XBLocalImageManager

+ (instancetype)sharedManager {
    static XBLocalImageManager *manager;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        manager = [XBLocalImageManager new];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        self.imageCache = [XBLocalImageCache sharedCache];
        self.imageLoader = [XBLocalImageLoader sharedLoader];
        self.operationContainers = [NSMutableArray new];
        self.loadQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        self.shouldDecodeImage = YES;
        self.imageCache.shouldDecodeImage = self.shouldDecodeImage;
        self.decoder = [XBLocalImageDecoder new];
    }
    
    return self;
}

- (void)setShouldDecodeImage:(BOOL)shouldDecodeImage {
    _shouldDecodeImage = shouldDecodeImage;
    self.imageCache.shouldDecodeImage = shouldDecodeImage;
}

- (void)safelyRemoveOperation:(XBLocalImageContainerOperation *)operation {
    @synchronized (self.operationContainers) {
        if (operation) {
            [self.operationContainers removeObject:operation];
        }
    }
}

- (void)safelyAddOperation:(XBLocalImageContainerOperation *)operation {
    @synchronized (self.operationContainers) {
        if (operation) {
            [self.operationContainers addObject:operation];
        }
    }
}


- (NSOperation *)loadImageWithNameOrPath:(NSString *)imageNameOrPath
                          options:(XBLocalImageOptions)options
                        completed:(XBLocalImageInternalCompletedBlock)completedBlock {
    __block XBLocalImageContainerOperation *operation = [XBLocalImageContainerOperation new];
    
    NSString *imagePath = [imageNameOrPath copy];
    if (imagePath.length == 0) {
        [self callCompletionBlockForOperation:operation
                                   completion:completedBlock
                                        error:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSURLLocalizedNameKey: @"image name or path can't be empty"}]
                                   nameOrPath:imageNameOrPath];
        return operation;
    }
    
    if (![imagePath containsString:@"."]) {
        //default png format
        imagePath = [imagePath stringByAppendingString:@".png"];
    }
    
    if (![imagePath hasPrefix:@"//"]) {
        //default main bundle
        imagePath = [[NSBundle mainBundle] pathForResource:imagePath ofType:nil];
    }
    
    if (imagePath.length == 0) {
        [self callCompletionBlockForOperation:operation
                                   completion:completedBlock
                                        error:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSURLLocalizedNameKey: @"image name or path can't be empty"}]
                                   nameOrPath:imageNameOrPath];
        return operation;
    }
    
    UIImage *image = [self.imageCache memoryCacheForKey:imagePath];
    if (image) {
        [self callCompletionBlockForOperation:operation completion:completedBlock image:image error:nil finished:YES nameOrPath:imageNameOrPath];
        return operation;
    }
    
    dispatch_async(self.loadQueue, ^{
        //因为是异步，所以cancle可能在downloadImageWithUrl发生
        if (operation.isCancelled) {return ;}
        
        __weak typeof(self) wself = self;
        __weak typeof (XBLocalImageContainerOperation *) woperation = operation;
        operation.token = [self.imageLoader loadImageWithPath:imagePath options:0 completed:^(UIImage *image, NSError *error, BOOL finished) {
            __strong typeof(woperation) soperation = woperation;
            __strong typeof(wself) sself = wself;
            if (!sself || !soperation) {return ;}
            
            if (!image || error) {
                [sself callCompletionBlockForOperation:operation completion:completedBlock error:error nameOrPath:imageNameOrPath];
                [sself safelyRemoveOperation:soperation];
                return;
            }
            
            if (sself.shouldDecodeImage) {
                image = [sself.decoder decodeImage:image];
            }
            
            //not main thread
            if (image && finished) {
                [sself.imageCache saveImage:image forKey:imagePath];
            }
            [sself callCompletionBlockForOperation:soperation completion:completedBlock image:image error:error finished:finished nameOrPath:imageNameOrPath];
            
            if (finished) {
                [sself safelyRemoveOperation:soperation];
            }

        }];
        [self safelyAddOperation:operation];
    });
    
    return operation;
}


- (void)callCompletionBlockForOperation:(NSOperation *)operation
                             completion:(XBLocalImageInternalCompletedBlock)completionBlock
                                  error:(NSError *)error
                             nameOrPath:(NSString *)nameOrPath {
    [self callCompletionBlockForOperation:operation completion:completionBlock image:nil error:error finished:YES nameOrPath:nameOrPath];
}

- (void)callCompletionBlockForOperation:(NSOperation *)operation
                             completion:(XBLocalImageInternalCompletedBlock)completionBlock
                                  image:(UIImage *)image
                                  error:(NSError *)error
                               finished:(BOOL)finished
                             nameOrPath:(NSString *)nameOrPath {
    if (completionBlock && operation && !operation.isCancelled) {
        dispatch_main_async_safe(^{
            completionBlock(image, error, finished, nameOrPath);
        });
    }
}

@end




@implementation XBLocalImageContainerOperation

- (void)cancel {
    self.cancel = YES;
    
    if (self.token) {
        [[XBLocalImageLoader sharedLoader] cancel:self.token];
        self.token = nil;
    }
    
    [[XBLocalImageManager sharedManager] safelyRemoveOperation:self];
}



@end
