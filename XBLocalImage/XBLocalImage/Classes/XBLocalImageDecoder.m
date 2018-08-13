//
//  XBLocalImageDecoder.m
//  XBLocalImage
//
//  Created by xiabob on 2018/8/13.
//  Copyright © 2018年 xiabob. All rights reserved.
//

#import "XBLocalImageDecoder.h"

@implementation XBLocalImageDecoder

- (CGColorSpaceRef)deviceRGB {
    static CGColorSpaceRef rgb;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        //You are responsible for releasing this object by calling CGColorSpaceRelease.
        //这里直接使用单例的方式
        rgb = CGColorSpaceCreateDeviceRGB();
    });
    return rgb;
}

- (UIImage *)decodeImage:(UIImage *)image {
    if (!image) {return nil;}
    
    //http://blog.leichunfeng.com/blog/2017/02/20/talking-about-the-decompression-of-the-image-in-ios/
    CGImageRef imageRef = image.CGImage;
    size_t width = CGImageGetWidth(imageRef); size_t height = CGImageGetHeight(imageRef);
    
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
    BOOL hasAlphaInfo = NO;
    if (alphaInfo == kCGImageAlphaPremultipliedFirst ||
        alphaInfo == kCGImageAlphaPremultipliedLast ||
        alphaInfo == kCGImageAlphaFirst ||
        alphaInfo == kCGImageAlphaLast) {
        hasAlphaInfo = YES;
    }
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    //for premultiplied ARGB or XRGB
    bitmapInfo |= hasAlphaInfo ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, [self deviceRGB], bitmapInfo);
    if (!context) {return image;}
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef); //decode
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    CFRelease(newImageRef);
    CFRelease(context);
    
    return newImage;
}

@end
