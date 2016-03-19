//
//  UIImage+Common.h
//  HLMagic
//
//  Created by marujun on 13-12-8.
//  Copyright (c) 2013年 chen ying. All rights reserved.
//

#import <UIKit/UIKit.h>

CGFloat DegreesToRadians(CGFloat degrees);
CGFloat RadiansToDegrees(CGFloat radians);

@interface UIImage (Common)

+ (UIImage *)screenshot;
+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)imageWithColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius;
+ (UIImage *)imageWithView:(UIView *)view;
- (UIImage *)squareImage;
- (UIImage *)imageScaledToSize:(CGSize)newSize;
- (UIImage *)imageClipedWithRect:(CGRect)clipRect;

/** 模糊化图片 */
- (UIImage *)imageBluredByRadius:(CGFloat)radius;

/** 黑白图片 */
- (UIImage*)monochromeImage;

/** 灰度化图片 */
- (UIImage *)grayscaleImage;

/** 修正图片的方向信息 */
- (UIImage *)fixOrientation;

/** 通过弧度旋转图片 */
- (UIImage *)imageRotatedByRadians:(CGFloat)radians;

/** 通过角度旋转图片 */
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;

/** 反转后的遮罩图片，效果：纯白色表示被遮罩区域将完全透明，纯黑色表示被遮罩区域将会原封不动保留下来，
 灰色部分(0x000000~0xFFFFFF)表示被遮罩区域将会处理成半透明的效果 */
- (UIImage *)inverseMaskImage;

@end
