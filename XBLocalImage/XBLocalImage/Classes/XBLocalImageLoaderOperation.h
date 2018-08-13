//
//  XBLocalImageLoaderOperation.h
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XBLocalImageLoader.h"

@interface XBLocalImageLoaderOperation : NSOperation

- (instancetype)initWithImagePath:(NSString *)imagePath;

- (BOOL)cancel:(id)callback;
- (NSMutableDictionary *)addCompletedBlock:(XBLocalImageLoadCompletedBlock)completeBlock;

@end
