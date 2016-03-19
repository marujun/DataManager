//
//  USViewController.h
//  USEvent
//
//  Created by marujun on 15/9/8.
//  Copyright (c) 2015年 MaRuJun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "USTransitionAnimator.h"

@interface USViewController : UIViewController
{
    float _topInset;
    
    USNavigationTransitionOption _transitionOption;
}

@property(nonatomic, assign) float topInset;

@property(nonatomic, strong) UILabel *navigationLine;
@property(nonatomic, strong) UINavigationBar *navigationBar;
@property(nonatomic, strong) UINavigationItem *myNavigationItem;

@property (nonatomic, assign) USNavigationTransitionOption transitionOption;

/** 是否允许屏幕边缘侧滑手势 */
@property (nonatomic, assign) BOOL enableScreenEdgePanGesture;


- (void)updateDisplay;

+ (instancetype)viewController;

- (UIViewController *)viewControllerWillPushForLeftDirectionPan;

@end
