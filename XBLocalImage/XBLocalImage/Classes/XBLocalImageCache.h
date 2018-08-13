//
//  XBLocalImageCache.h
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^XBClearCacheCompletedBlock)();

@interface XBLocalImageCache : NSObject

/** limits are imprecise/not strict */
@property (nonatomic, assign) NSUInteger totalCostLimit;

/** limits are imprecise/not strict */
@property (nonatomic, assign) NSUInteger countLimit;

/** 是否提前将图片解码，默认是YES */
@property (nonatomic, assign) BOOL shouldDecodeImage;

+ (instancetype)sharedCache;

- (UIImage *)memoryCacheForKey:(NSString *)key;
- (void)saveImage:(UIImage *)image forKey:(NSString *)key;

- (void)clearMemoryCache;

@end
