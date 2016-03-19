//
//  USTransitionAnimator.m
//  USNavAnimation
//
//  Created by marujun on 15/12/26.
//  Copyright © 2015年 MaRuJun. All rights reserved.
//

#import "USTransitionAnimator.h"

@implementation USTransitionAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
}

@end

@implementation USFadeTransitionAnimator

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [containerView addSubview:toViewController.view];
    
    if (!_reversed) {
        toViewController.view.frame = containerView.bounds;
        toViewController.view.alpha = 0;
    }
    else {
        toViewController.view.alpha = 1;
        [containerView bringSubviewToFront:fromViewController.view];
    }
    
    void (^animations)(void) = ^(void) {
        if(!_reversed) toViewController.view.alpha = 1;
        else fromViewController.view.alpha = 0;
    };
    
    void (^completion)(BOOL finished) = ^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    };
    
    if (_interactive) {
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.f
                            options:UIViewAnimationOptionCurveLinear animations:animations completion:completion];
    } else {
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:animations completion:completion];
    }
}

@end

@implementation USFlipTransitionAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 1.0;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [containerView addSubview:toViewController.view];
    
    UIViewAnimationOptions options = UIViewAnimationOptionTransitionFlipFromLeft;
    if (!_reversed) {
        options = UIViewAnimationOptionTransitionFlipFromRight;
    }
    else {
        toViewController.view.alpha = 1;
        [containerView bringSubviewToFront:fromViewController.view];
    }
    //偶尔出现返回之后frame变了（不可复现），所以重新设置一下
    toViewController.view.frame = containerView.bounds;
    
    [CATransaction flush];
    [UIView transitionWithView:containerView
                      duration:[self transitionDuration:transitionContext]
                       options:options
                    animations: ^{
                        fromViewController.view.hidden = YES;
                    }
                    completion:^(BOOL finished) {
                        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                        fromViewController.view.hidden = NO;
                    }];
}

@end

@implementation USScaleTransitionAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.35;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [containerView addSubview:toViewController.view];
    
    _cancel = NO;
    
    UIView *snapshotView = [_dataSource snapshotViewWithScaleAnimator:self];
    NSArray *fadeViews = [_dataSource fadeViewsWithScaleAnimator:self];
    CGRect beginRect = [_dataSource beginRectWithScaleAnimator:self];
    CGRect endRect = [_dataSource endRectWithScaleAnimator:self];
    
    NSAssert(snapshotView, @"过渡动画中的镜像视图不能为nil");
    
    UIViewAnimationOptions options = UIViewAnimationOptionTransitionFlipFromLeft;
    if (!_reversed) {
        options = UIViewAnimationOptionTransitionFlipFromRight;
        toViewController.view.frame = containerView.bounds;
        for (UIView *itemView in fadeViews) itemView.alpha = 0;
    }
    else {
        toViewController.view.alpha = 1;
        [containerView bringSubviewToFront:fromViewController.view];
    }
    
    snapshotView.translatesAutoresizingMaskIntoConstraints = YES;
    snapshotView.frame = _reversed?endRect:beginRect;
    snapshotView.hidden = NO;
    
    if ([_dataSource respondsToSelector:@selector(snapshotViewDidPresented:)]) {
        [_dataSource snapshotViewDidPresented:self];
    }
    
    void (^completeBlock)(BOOL finished) = ^(BOOL finished){
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        
        snapshotView.hidden = YES;
        if ([_dataSource respondsToSelector:@selector(snapshotViewDidDismiss:)]) {
            [_dataSource snapshotViewDidDismiss:self];
        }
    };
    
    if (_cancel) {
        if (_reversed) {
            snapshotView.hidden = YES;
            [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                fromViewController.view.alpha = 0;
            } completion:completeBlock];
        }
        else {
            for (UIView *itemView in fadeViews) itemView.alpha = _reversed?0:1;
            completeBlock(YES);
        }
    }
    else {
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            for (UIView *itemView in fadeViews) itemView.alpha = _reversed?0:1;
            snapshotView.frame = _reversed?beginRect:endRect;
        } completion:completeBlock];
    }
}

@end


@implementation USSysTransitionAnimator

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [containerView addSubview:toViewController.view];
    
    UIView *maskView = [[UIView alloc] initWithFrame:containerView.bounds];
    maskView.backgroundColor = [UIColor blackColor];
    
    UIView *shadowView = [[UIView alloc] init];
    shadowView.backgroundColor = [UIColor grayColor];
    shadowView.layer.shadowOffset =CGSizeMake(0.f, 0.f);
    shadowView.layer.shadowRadius = 6.f;
    shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
    shadowView.layer.shadowOpacity = 0.8;
    
    CGRect toRect = containerView.bounds;
    CGFloat xOffset = toRect.size.width*3.f/10.f;
    CGRect fromRect = fromViewController.view.frame;
    CGRect shadowRect = CGRectMake(0, 0, 10, toRect.size.height);
    
    if (!_reversed) {
        toRect.origin.x = toRect.size.width;
        toViewController.view.frame = toRect;
        
        shadowRect.origin.x = toRect.origin.x;
        shadowView.frame = shadowRect;
        [containerView insertSubview:maskView aboveSubview:fromViewController.view];
        
        toRect.origin.x = 0;
        fromRect.origin.x = -xOffset;
        shadowRect.origin.x = toRect.origin.x;
    }
    else {
        toRect.origin.x = -xOffset;
        toViewController.view.alpha = 1;
        toViewController.view.frame = toRect;
        
        shadowRect.origin.x = fromRect.origin.x;
        shadowView.frame = shadowRect;
        [containerView bringSubviewToFront:fromViewController.view];
        [containerView insertSubview:maskView belowSubview:fromViewController.view];
        
        toRect.origin.x = 0;
        fromRect.origin.x = fromRect.size.width;
        shadowRect.origin.x = fromRect.origin.x;
    }
    [containerView insertSubview:shadowView aboveSubview:maskView];
    
    maskView.alpha = _reversed?0.1:0;
    shadowView.alpha = _reversed?0.5:0;
    
    void (^animations)(void) = ^(void) {
        toViewController.view.frame = toRect;
        fromViewController.view.frame = fromRect;
        
        maskView.alpha = _reversed?0:0.1;
        shadowView.alpha = _reversed?0:0.5;
        shadowView.frame = shadowRect;
    };
    
    void (^completion)(BOOL finished) = ^(BOOL finished) {
        [maskView removeFromSuperview];
        [shadowView removeFromSuperview];
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
    };
    
    if (_interactive) {
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.f
                            options:UIViewAnimationOptionCurveLinear animations:animations completion:completion];
    } else {
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.f usingSpringWithDamping:1.f
              initialSpringVelocity:1.f options:UIViewAnimationOptionCurveEaseInOut animations:animations completion:completion];
    }
}

@end


@implementation USPresentTransitionAnimator

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [containerView addSubview:toViewController.view];
    
    UIViewController *targetViewController;
    CGRect bounds = containerView.bounds;
    CGRect transitionFrame;
    
    switch (self.option) {
        case USNavigationTransitionOptionFromRight:
            transitionFrame = CGRectMake(bounds.size.width, 0, bounds.size.width, bounds.size.height);
            break;
        case USNavigationTransitionOptionFromLeft:
            transitionFrame = CGRectMake(-bounds.size.width, 0, bounds.size.width, bounds.size.height);
            break;
        case USNavigationTransitionOptionFromTop:
            transitionFrame = CGRectMake(0, -bounds.size.height, bounds.size.width, bounds.size.height);
            break;
        case USNavigationTransitionOptionFromBottom:
            transitionFrame = CGRectMake(0, bounds.size.height, bounds.size.width, bounds.size.height);
            break;
        default:
            break;
    }
    
    if (!_reversed) {
        targetViewController = toViewController;
        targetViewController.view.frame = transitionFrame;
    } else {
        targetViewController = fromViewController;
        [containerView bringSubviewToFront:fromViewController.view];
    }
    
    void (^animations)(void) = ^(void) {
        if(_reversed) targetViewController.view.frame = transitionFrame;
        else targetViewController.view.frame = bounds;
    };
    
    void (^completion)(BOOL finished) = ^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    };
    
    if (_interactive) {
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.f
                            options:UIViewAnimationOptionCurveLinear animations:animations completion:completion];
    } else {
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.f usingSpringWithDamping:1.f
              initialSpringVelocity:1.f options:UIViewAnimationOptionCurveEaseInOut animations:animations completion:completion];
    }
}

@end
