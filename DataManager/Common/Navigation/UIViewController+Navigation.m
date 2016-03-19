//
//  UIViewController+Navigation.m
//  HLSNS
//
//  Created by 刘波 on 12-12-4.
//  Copyright (c) 2012年 hoolai. All rights reserved.
//

#import "UIViewController+Navigation.h"
#import "USViewController.h"

@implementation UIViewController (Navigation)

- (void)setNavigationBackButtonDefault
{
    NSString *title = nil;
    NSArray *array = self.navigationController.viewControllers;
    if (array && array.count >= 2) {
        title = [array[array.count-2] title];
    }
    
    [self setNavBackButtonWithTitle:title];
}

- (void)setNavBackButtonWithTitle:(NSString *)title
{
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 46, 44)];
    [backButton setTitleColor:RGBCOLOR(255, 255, 255) forState:UIControlStateNormal];
    backButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [backButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 0)];
    
    [backButton setImage:[UIImage imageNamed:(@"pub_nav_white_back.png")] forState:UIControlStateNormal];
    [backButton setTitleColor:RGBCOLOR(136, 136, 136) forState:UIControlStateHighlighted];
    if (!title || !title.length) title = @"";
    [backButton setTitle:title forState:UIControlStateNormal];
    
    float width = [title stringWidthWithFont:backButton.titleLabel.font height:44];
    backButton.frame = CGRectMake(0, 0, MAX(MIN(width, 60)+20, 44), 44);
    
    [self setNavigationBackButton:backButton];
    [backButton setExclusiveTouch:YES];
}

- (void)setNavigationBackButton:(UIButton *)button
{
    [button addTarget:self action:@selector(navigationBackButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self setNavigationLeftView:button];
}

- (void)navigationBackButtonAction:(UIButton *)sender
{
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)setNavigationLeftView:(UIView *)view
{
    if ([view isKindOfClass:[UIButton class]]) {
        [(UIButton *)view setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    }
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:view];
    
    // 调整 leftBarButtonItem 在 iOS6 下面的位置
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if(floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1){
        negativeSpacer.width = 5;  //向右移动5个像素
    }else{
        negativeSpacer.width = -6;  //向左移动6个像素
    }
    
    //不是双语按钮的情况
    if (![view.accessibilityLabel isEqual:@"bilingual"]) {
        //在us.上统一再向右移10个像素
        negativeSpacer.width += 10;
    }
    
    if ([self respondsToSelector:@selector(myNavigationItem)] && ((USViewController *)self).myNavigationItem) {
        ((USViewController *)self).myNavigationItem.leftBarButtonItems = @[negativeSpacer, buttonItem];
    }else{
        self.navigationItem.leftBarButtonItems = @[negativeSpacer, buttonItem];
    }
}

- (void)setNavigationRightView:(UIView *)view
{
    if ([view isKindOfClass:[UIButton class]]) {
        [(UIButton *)view setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    }
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:view];
    
    // 调整 rightBarButtonItem 在 iOS6 下面的位置
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if(floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1){
        negativeSpacer.width = 5;  //向左移动5个像素
    }else{
        negativeSpacer.width = -5;  //向右移动5个像素
    }
    
    //在us.上统一再向左移10个像素
    negativeSpacer.width += 10;
    
    if ([self respondsToSelector:@selector(myNavigationItem)] && ((USViewController *)self).myNavigationItem) {
        ((USViewController *)self).myNavigationItem.rightBarButtonItems = @[negativeSpacer, buttonItem];
    }else{
        self.navigationItem.rightBarButtonItems = @[negativeSpacer, buttonItem];
    }
}

- (void)setNavigationRightViews:(NSArray *)views
{
    UIView *parentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    parentView.backgroundColor = [UIColor clearColor];
    parentView.clipsToBounds = YES;
    
    [self setNavigationRightView:parentView];
    
    UIView *view1 = [views objectAtIndex:0];
    UIView *view2 = [views objectAtIndex:1];
    [parentView addSubview:view1];
    [parentView addSubview:view2];
    
    CGRect parentFrame = parentView.frame;
    CGRect view1Frame = view1.frame;
    CGRect view2Frame = view1.frame;
    
    view2Frame.origin.x = parentFrame.size.width-view2Frame.size.width;
    view2Frame.origin.y = (parentFrame.size.height-view2Frame.size.height)/2;
    view1Frame.origin.x = view2Frame.origin.x-view1Frame.size.width;
    view1Frame.origin.y = view2Frame.origin.y;
    
    view1.frame = view1Frame;
    view2.frame = view2Frame;
}

- (void)setNavigationTitleView:(UIView *)view
{
    if ([self respondsToSelector:@selector(myNavigationItem)] && ((USViewController *)self).myNavigationItem) {
        ((USViewController *)self).myNavigationItem.titleView = view;
    }else{
        self.navigationItem.titleView = view;
    }
}

@end
