//
//  XBLocalImageManager.h
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//有的系统框架更要求在主队列，而不仅仅是主线程
#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
block();\
} else {\
    dispatch_async(dispatch_get_main_queue(), block);\
}
#endif


typedef NS_OPTIONS(NSUInteger, XBLocalImageOptions) {
    /** set operation low queuePriority */
    XBLocalImageOptionsLowPriority = 1<<0,
    
    /** set operation high queuePriority */
    XBLocalImageOptionsHighPriority = 1<<1,
};

typedef void(^XBLocalImageExternalCompletedBlock)(UIImage *image, NSError *error, NSString *nameOrPath);
typedef void(^XBLocalImageInternalCompletedBlock)(UIImage *image, NSError *error, BOOL finished, NSString *nameOrPath);

@interface XBLocalImageManager : NSObject

/** 是否提前将图片解码，默认是YES */
@property (nonatomic, assign) BOOL shouldDecodeImage;


+ (instancetype)sharedManager;

- (NSOperation *)loadImageWithNameOrPath:(NSString *)imageNameOrPath
                                 options:(XBLocalImageOptions)options
                               completed:(XBLocalImageInternalCompletedBlock)completedBlock;

@end
