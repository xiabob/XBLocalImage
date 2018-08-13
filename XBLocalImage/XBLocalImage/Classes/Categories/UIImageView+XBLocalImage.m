//
//  UIImageView+XBLocalImage.m
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import "UIImageView+XBLocalImage.h"
#import "UIView+XBLocalImage.h"

@implementation UIImageView (XBLocalImage)

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
    [self xb_internalSetImageWithNamePath:nameOrPath
                         placeholderImage:placeholder
                                  options:options
                             operationKey:NSStringFromClass([self class])
                            setImageBlock:nil
                                completed:completedBlock];
}

@end
