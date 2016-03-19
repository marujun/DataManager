//
//  UIViewController+Navigation.h
//  HLSNS
//
//  Created by 刘波 on 12-12-4.
//  Copyright (c) 2012年 hoolai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Navigation)

// 设置回退按钮
- (void)setNavigationBackButton:(UIButton *)button;
- (void)setNavBackButtonWithTitle:(NSString *)title;

- (void)navigationBackButtonAction:(UIButton *)sender;

// 设置默认回退按钮
- (void)setNavigationBackButtonDefault;

// 为navigationbar设置左视图
- (void)setNavigationLeftView:(UIView *)view;

// 为navigationbar设置右视图
-(void)setNavigationRightView:(UIView *)view;

// 为navigationbar设置右视图集
- (void)setNavigationRightViews:(NSArray *)views;

// 为navigationbar设置标题视图
- (void)setNavigationTitleView:(UIView *)view;

@end
