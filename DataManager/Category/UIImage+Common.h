//
//  UIImage+Common.h
//  HLMagic
//
//  Created by marujun on 13-12-8.
//  Copyright (c) 2013年 chen ying. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Common)

+ (UIImage *)defaultImage;
+ (UIImage *)defaultAvatar;
+ (UIImage *)defaultBigAvatar;
- (UIImage *)circleAvatarImage;

+ (UIImage *)screenshot;
+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)imageWithColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius;
+ (UIImage *)imageWithView:(UIView *)view;
- (UIImage *)squareImage;
- (UIImage *)imageScaledToSize:(CGSize)newSize;
- (UIImage *)imageClipedWithRect:(CGRect)clipRect;

//模糊化图片
- (UIImage *)bluredImageWithRadius:(CGFloat)radius;

//黑白图片
- (UIImage*)monochromeImage;

@end
