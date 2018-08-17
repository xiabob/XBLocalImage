//
//  CALayer+XBLocalImage.m
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import "CALayer+XBLocalImage.h"
#import <objc/runtime.h>

@implementation CALayer (XBLocalImage)

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath {
    [self xb_setImageWithNameOrPath:nameOrPath placeholderImage:nil];
}

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath
                          options:(XBLocalImageOptions)options {
    [self xb_setImageWithNameOrPath:nameOrPath placeholderImage:nil options:options];
}

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath
                 placeholderImage:(nullable UIImage *)placeholder {
    [self xb_setImageWithNameOrPath:nameOrPath placeholderImage:placeholder options:0];
}

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath
                 placeholderImage:(nullable UIImage *)placeholder
                          options:(XBLocalImageOptions)options {
    [self xb_setImageWithNameOrPath:nameOrPath placeholderImage:placeholder options:options completed:nil];
}

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath
                        completed:(nullable XBLocalImageExternalCompletedBlock)completedBlock {
    [self xb_setImageWithNameOrPath:nameOrPath placeholderImage:nil completed:completedBlock];
}

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath
                 placeholderImage:(nullable UIImage *)placeholder
                        completed:(nullable XBLocalImageExternalCompletedBlock)completedBlock {
    [self xb_setImageWithNameOrPath:nameOrPath placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath
          placeholderImage:(nullable UIImage *)placeholder
                   options:(XBLocalImageOptions)options
                 completed:(nullable XBLocalImageExternalCompletedBlock)completedBlock {
    NSString *validOperationKey = NSStringFromClass([self class]);
    [self xb_cancelContainerOperationWithKey:validOperationKey];
    dispatch_main_async_safe(^{
        [self xb_setImage:placeholder];
    });
    
    if (nameOrPath.length > 0) {
        __weak typeof(self) wself = self;
        NSOperation *operation = [[XBLocalImageManager sharedManager] loadImageWithNameOrPath:nameOrPath options:options completed:^(UIImage *image, NSError *error, BOOL finished, NSString *nameOrPath) {
            __strong typeof(wself) sself = wself;
            if (!sself) {return ;}
            
            dispatch_main_async_safe(^{
                if (!sself) {return ;}
                [sself xb_setImage:image];
                if (finished && completedBlock) {
                    completedBlock(image, error, nameOrPath);
                }
            });
        }];
        [self xb_setContainerOperation:operation forKey:validOperationKey];
    } else {
        dispatch_main_async_safe(^{
            if (completedBlock) {
                completedBlock(nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSURLLocalizedNameKey: @"url can't be empty"}], nil);
            }
        });
    }
}

- (void)xb_setImage:(UIImage *)image {
    if (!image) return;
    self.contents = (__bridge id _Nullable)([image CGImage]);
    //[self setNeedsDisplay]; 导致contents被重新设置了
}


#pragma mark - Container Operation

- (NSMutableDictionary *)containerOperationDictionary {
    NSMutableDictionary *operations = objc_getAssociatedObject(self, @selector(containerOperationDictionary));
    if (operations) {
        return operations;
    }
    
    objc_setAssociatedObject(self, @selector(containerOperationDictionary), [NSMutableDictionary new], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return operations;
}

- (void)xb_setContainerOperation:(NSOperation *)operation forKey:(NSString *)key {
    if (key.length > 0) {
        [self xb_cancelContainerOperationWithKey:key];
        if (operation) {
            NSMutableDictionary *operationDictionary = [self containerOperationDictionary];
            operationDictionary[key] = operation;
        }
    }
}

- (void)xb_cancelContainerOperationWithKey:(NSString *)key {
    if (key.length > 0) {
        NSMutableDictionary *operationDictionary = [self containerOperationDictionary];
        NSOperation *operation = operationDictionary[key];
        if (operation) {
            [operation cancel];
        }
        [operationDictionary removeObjectForKey:key];
    }
    
}


@end
