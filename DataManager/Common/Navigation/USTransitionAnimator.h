//
//  USTransitionAnimator.h
//  USNavAnimation
//
//  Created by marujun on 15/12/26.
//  Copyright © 2015年 MaRuJun. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, USNavigationTransitionOption) {
    USNavigationTransitionOptionNone = 0,       //系统默认动画
    USNavigationTransitionOptionFade,           //渐隐渐现动画
    USNavigationTransitionOptionFlip,           //3D翻转动画
    USNavigationTransitionOptionScale,          //类似相册的缩放动画
    USNavigationTransitionOptionSystem,         //模拟系统动画
    
    USNavigationTransitionOptionFromRight,      //从右边弹出动画
    USNavigationTransitionOptionFromLeft,       //从左边弹出动画
    USNavigationTransitionOptionFromTop,        //从顶部弹出动画
    USNavigationTransitionOptionFromBottom,     //从底部弹出动画
};

@interface USTransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>
{
    BOOL _reversed;
    BOOL _interactive;
}

@property (nonatomic, assign) BOOL reversed;
@property (nonatomic, assign) BOOL interactive;

@end

@interface USFadeTransitionAnimator : USTransitionAnimator

@end

@interface USFlipTransitionAnimator : USTransitionAnimator

@end

@class USScaleTransitionAnimator;
@protocol USScaleTransitionAnimatorDataSource <NSObject>
@required
- (CGRect)beginRectWithScaleAnimator:(USScaleTransitionAnimator *)animator;
- (CGRect)endRectWithScaleAnimator:(USScaleTransitionAnimator *)animator;
- (NSArray<UIView *> *)fadeViewsWithScaleAnimator:(USScaleTransitionAnimator *)animator;
- (UIView *)snapshotViewWithScaleAnimator:(USScaleTransitionAnimator *)animator;

@optional
- (void)snapshotViewDidPresented:(USScaleTransitionAnimator *)animator;
- (void)snapshotViewDidDismiss:(USScaleTransitionAnimator *)animator;

@end

@interface USScaleTransitionAnimator : USTransitionAnimator

@property (nonatomic, assign) BOOL cancel;
@property (nonatomic, weak) id<USScaleTransitionAnimatorDataSource> dataSource;

@end

@interface USSysTransitionAnimator : USTransitionAnimator

@end

@interface USPresentTransitionAnimator : USTransitionAnimator

@property (nonatomic, assign) USNavigationTransitionOption option;

@end