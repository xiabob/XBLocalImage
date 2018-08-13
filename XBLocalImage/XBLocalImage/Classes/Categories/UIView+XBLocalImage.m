//
//  UIView+XBLocalImage.m
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import "UIView+XBLocalImage.h"
#import <objc/runtime.h>

@implementation UIView (XBLocalImage)

- (void)xb_internalSetImageWithNamePath:(NSString *)nameOrPath
                       placeholderImage:(UIImage *)placeholder
                                options:(XBLocalImageOptions)options
                           operationKey:(NSString *)operationKey
                          setImageBlock:(XBSetImageBlock)setImageBlock
                              completed:(XBLocalImageExternalCompletedBlock)completedBlock {
    NSString *validOperationKey = operationKey ?: NSStringFromClass([self class]);
    //取消正在进行中的operation，同时使得在获取图片之前显示的是placeholder或者空白(placeholder为nil)，这样在类似tableview需要复用cell视图中才会表现正常
    [self xb_cancelContainerOperationWithKey:validOperationKey];
    dispatch_main_async_safe(^{
        [self xb_setImage:placeholder basedOnSetImageBlock:setImageBlock];
    });
    
    if (nameOrPath.length > 0) {
        __weak typeof(self) wself = self;
        NSOperation *operation = [[XBLocalImageManager sharedManager] loadImageWithNameOrPath:nameOrPath options:options completed:^(UIImage *image, NSError *error, BOOL finished, NSString *nameOrPath) {
            __strong typeof(wself) sself = wself;
            if (!sself) {return ;}
            
            dispatch_main_async_safe(^{
                if (!sself) {return ;}
                [sself xb_setImage:image basedOnSetImageBlock:setImageBlock];
                if (finished && completedBlock) {
                    completedBlock(image, error, nameOrPath);
                }
            });
        }];
        [self xb_setContainerOperation:operation forKey:validOperationKey];
    } else {
        dispatch_main_async_safe(^{
            if (completedBlock) {
                completedBlock(nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSURLLocalizedNameKey: @"name or path can't be empty"}], nil);
            }
        });
    }
}

- (void)xb_setImage:(UIImage *)image basedOnSetImageBlock:(XBSetImageBlock)setImageBlock {
    if (setImageBlock) {
        return setImageBlock(image);
    }
    
    if ([self isKindOfClass:[UIImageView class]]) {
        ((UIImageView *)self).image = image;
    } else if ([self isKindOfClass:[UIButton class]]) {
        [((UIButton *)self) setImage:image forState:UIControlStateNormal];
    }
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
