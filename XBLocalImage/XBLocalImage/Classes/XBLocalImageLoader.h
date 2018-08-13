//
//  XBLocalImageLoader.h
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^XBLocalImageLoadCompletedBlock)(UIImage *image, NSError *error, BOOL finished);

typedef NS_ENUM(NSUInteger, XBLocalImageLoaderOptions) {
    /** set operation low queuePriority */
    XBLocalImageLoaderOptionsLowPriority = 1<<0,
    
    /** set operation high queuePriority */
    XBLocalImageLoaderOptionsHighPriority = 1<<1,
};

typedef NS_ENUM(NSUInteger, XBLocalImageLoaderExecutionOrder) {
    XBLocalImageLoaderExecutionOrderFIFO = 1<<0,
    XBLocalImageLoaderExecutionOrderFILO = 1<<1,
};


@interface XBLocalImageLoaderToken : NSObject

@property (nonatomic,   copy) NSString *path;
@property (nonatomic, strong) id callback;

@end


@interface XBLocalImageLoader : NSObject

@property (nonatomic, assign) NSUInteger maxConcurrentLoad;

/** 设置operation的执行顺序，默认是XBWebImageDownloaderExecutionOrderFIFO，先进先出 */
@property (nonatomic, assign) XBLocalImageLoaderExecutionOrder executionOrder;


+ (instancetype)sharedLoader;

- (XBLocalImageLoaderToken *)loadImageWithPath:(NSString *)imagePath
                                       options:(XBLocalImageLoaderOptions)options
                                     completed:(XBLocalImageLoadCompletedBlock)completedBlock;

- (void)cancel:(XBLocalImageLoaderToken *)token;
- (void)cancelAllOperations;

@end
