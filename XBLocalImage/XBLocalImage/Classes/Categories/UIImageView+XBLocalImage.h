//
//  UIImageView+XBLocalImage.h
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XBLocalImageManager.h"

@interface UIImageView (XBLocalImage)

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath;

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath
                          options:(XBLocalImageOptions)options;

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath
                 placeholderImage:(nullable UIImage *)placeholder;

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath
                 placeholderImage:(nullable UIImage *)placeholder
                          options:(XBLocalImageOptions)options;

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath
                        completed:(nullable XBLocalImageExternalCompletedBlock)completedBlock;

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath
                 placeholderImage:(nullable UIImage *)placeholder
                        completed:(nullable XBLocalImageExternalCompletedBlock)completedBlock;

- (void)xb_setImageWithNameOrPath:(nullable NSString *)nameOrPath
                 placeholderImage:(nullable UIImage *)placeholder
                          options:(XBLocalImageOptions)options
                        completed:(nullable XBLocalImageExternalCompletedBlock)completedBlock;

@end
