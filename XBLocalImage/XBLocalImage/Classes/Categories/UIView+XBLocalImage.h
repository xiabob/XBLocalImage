//
//  UIView+XBLocalImage.h
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XBLocalImageManager.h"

typedef void(^XBSetImageBlock)(UIImage *image);

@interface UIView (XBLocalImage)

- (void)xb_internalSetImageWithNamePath:(NSString *)nameOrPath
                       placeholderImage:(UIImage *)placeholder
                                options:(XBLocalImageOptions)options
                           operationKey:(NSString *)operationKey
                          setImageBlock:(XBSetImageBlock)setImageBlock
                              completed:(XBLocalImageExternalCompletedBlock)completedBlock;

@end
