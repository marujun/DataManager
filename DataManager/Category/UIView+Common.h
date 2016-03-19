//
//  UIView+Common.h
//  HLMagic
//
//  Created by marujun on 13-12-8.
//  Copyright (c) 2013年 chen ying. All rights reserved.
//

#import <UIKit/UIKit.h>

#define KeyboardAnimationCurve  7 << 16
#define KeyboardAnimationDuration  0.25

@interface BlurView : UIView

// Use the following property to set the tintColor. Set it to nil to reset.
@property (nonatomic, strong) UIColor *blurTintColor;

@end

@interface UIView (Common)

- (UIView *)findFirstResponder;

- (void)setBlurColor:(UIColor *)blurColor;

- (UIViewController *)nearsetViewController;

/** Set the anchorPoint of view without changing is perceived position. */
- (void)setAnchorPointMotionlessly:(CGPoint)anchorPoint xConstraint:(NSLayoutConstraint *)xConstraint yConstraint:(NSLayoutConstraint *)yConstraint;

//添加动画遮罩 并在duration秒之后移除
- (void)addMaskViewWithDuration:(float)duration;

//标题View（是否loadingView）
+ (UIView *)titileViewWithTitle:(NSString *)title activity:(BOOL)activity;

//标题View（带图片）
+ (UIView *)titileViewWithTitle:(NSString *)title image:(UIImage *)image;

//注意： 必须使用weakSelf : __weak typeof(self) weakSelf = self;
- (void)setTapActionWithBlock:(void (^)(void))block;

- (void)setPanActionWithBlock:(void (^)(void))block;

- (void) sizeLayoutToFit;

@end
