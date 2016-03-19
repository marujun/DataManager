//
//  UIView+Common.m
//  HLMagic
//
//  Created by marujun on 13-12-8.
//  Copyright (c) 2013年 chen ying. All rights reserved.
//

#import "UIView+Common.h"
#import <objc/runtime.h>

@interface BlurView ()

@property (nonatomic, strong) UIToolbar *toolbar;

@end

@implementation BlurView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    // If we don't clip to bounds the toolbar draws a thin shadow on top
    [self setClipsToBounds:YES];
    
    if (![self toolbar]) {
        [self setToolbar:[[UIToolbar alloc] initWithFrame:[self bounds]]];
        [self.toolbar setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self insertSubview:[self toolbar] atIndex:0];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_toolbar]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:NSDictionaryOfVariableBindings(_toolbar)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_toolbar]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:NSDictionaryOfVariableBindings(_toolbar)]];
    }
}

- (void)setBlurTintColor:(UIColor *)blurTintColor {
    if ([self.toolbar respondsToSelector:@selector(setBarTintColor:)]) {
        [self.toolbar setBarTintColor:blurTintColor];
    }else{
//        [self.toolbar setTintColor:blurTintColor];
        
        [self.toolbar setBackgroundColor:blurTintColor];
        [self.toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    }
}

@end

@implementation UIView (Common)

- (UIView *)findFirstResponder
{
    if (self.isFirstResponder) {
        return self;
    }
    
    for (UIView *subView in self.subviews) {
        UIView *firstResponder = [subView findFirstResponder];
        
        if (firstResponder != nil) {
            return firstResponder;
        }
    }
    
    return nil;
}

- (void)setBlurColor:(UIColor *)blurColor
{
    BlurView *blurView = nil;
    for (UIView *subview in self.subviews){
        if ([subview isKindOfClass:[BlurView class]]){
            blurView = (BlurView *)subview;
            break;
        }
    }
    if (!blurView) {
        blurView = [BlurView newAutoLayoutView];
        [self insertSubview:blurView atIndex:0];
        [blurView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }
    self.backgroundColor = [UIColor clearColor];
    [blurView setBlurTintColor:blurColor];
}

#pragma mark - 获取父 viewController
- (UIViewController *)nearsetViewController
{
    UIViewController *viewController = nil;
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            viewController = (UIViewController*)nextResponder;
            break;
        }
    }
    return viewController;
}

/**
 Set the anchorPoint of view without changing is perceived position.
 
 @param view view whose anchorPoint we will mutate
 @param anchorPoint new anchorPoint of the view in unit coords (e.g., {0.5,1.0})
 @param xConstraint an NSLayoutConstraint whose constant property adjust's view x.center
 @param yConstraint an NSLayoutConstraint whose constant property adjust's view y.center
 
 As multiple constraints can contribute to determining a view's center, the user of this
 function must specify which constraint they want modified in order to compensate for the
 modification in anchorPoint
 */
- (void)setAnchorPointMotionlessly:(CGPoint)anchorPoint xConstraint:(NSLayoutConstraint *)xConstraint yConstraint:(NSLayoutConstraint *)yConstraint
{
    // assert: old and new anchorPoint are in view's unit coords
    CGPoint const oldAnchorPoint = self.layer.anchorPoint;
    CGPoint const newAnchorPoint = anchorPoint;
    
    // Calculate anchorPoints in view's absolute coords
    CGPoint const oldPoint = CGPointMake(self.bounds.size.width * oldAnchorPoint.x,
                                         self.bounds.size.height * oldAnchorPoint.y);
    CGPoint const newPoint = CGPointMake(self.bounds.size.width * newAnchorPoint.x,
                                         self.bounds.size.height * newAnchorPoint.y);
    
    // Calculate the delta between the anchorPoints
    CGPoint const delta = CGPointMake(newPoint.x-oldPoint.x, newPoint.y-oldPoint.y);
    
    // get the x & y constraints constants which were contributing to the current
    // view's position, and whose constant properties we will tweak to adjust its position
    CGFloat const oldXConstraintConstant = xConstraint.constant;
    CGFloat const oldYConstraintConstant = yConstraint.constant;
    
    // calculate new values for the x & y constraints, from the delta in anchorPoint
    // when autolayout recalculates the layout from the modified constraints,
    // it will set a new view.center that compensates for the affect of the anchorPoint
    CGFloat const newXConstraintConstant = oldXConstraintConstant + delta.x;
    CGFloat const newYConstraintConstant = oldYConstraintConstant + delta.y;
    
    self.layer.anchorPoint = newAnchorPoint;
    xConstraint.constant = newXConstraintConstant;
    yConstraint.constant = newYConstraintConstant;
    [self setNeedsLayout];
}

+ (UIView *)titileViewWithTitle:(NSString *)title activity:(BOOL)activity
{
    UILabel *bigLabel = [[UILabel alloc] init];
    bigLabel.text = title;
    bigLabel.backgroundColor = [UIColor clearColor];
//    bigLabel.textColor = [UIColor blackColor];
    bigLabel.textColor = [UIColor whiteColor];
    bigLabel.font = [UIFont boldSystemFontOfSize:17];
    bigLabel.adjustsFontSizeToFitWidth = YES;
    [bigLabel sizeToFit];
    
    CGRect rect = bigLabel.frame;
    UIView *titleView = [[UIView alloc] initWithFrame:rect];
    titleView.backgroundColor = [UIColor clearColor];
    
    if (activity) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [activityView startAnimating];
        CGRect activityRect = activityView.bounds;
        activityRect.origin.y = (rect.size.height-activityRect.size.height)/2;
        activityView.frame = activityRect;
        [titleView addSubview:activityView];
        
        rect.origin.x = activityRect.size.width+5;
        bigLabel.frame = rect;
    }
    [titleView addSubview:bigLabel];
    
    CGRect titleFrame = CGRectMake(0, 0, 0, rect.size.height);
    titleFrame.size.width = rect.origin.x+rect.size.width;
    titleView.frame = titleFrame;
    
    return titleView;
}

+ (UIView *)titileViewWithTitle:(NSString *)title image:(UIImage *)image
{
    UILabel *bigLabel = [[UILabel alloc] init];
    bigLabel.text = title;
    bigLabel.backgroundColor = [UIColor clearColor];
//    bigLabel.textColor = [UIColor blackColor];
    bigLabel.textColor = [UIColor whiteColor];
    bigLabel.font = [UIFont boldSystemFontOfSize:17];
    bigLabel.adjustsFontSizeToFitWidth = YES;
    [bigLabel sizeToFit];
    
    CGRect rect = bigLabel.frame;
    UIView *titleView = [[UIView alloc] initWithFrame:rect];
    titleView.backgroundColor = [UIColor clearColor];
    [titleView addSubview:bigLabel];
    
    if (image) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        CGRect imageRect = CGRectMake(0, 0, 15, 15);
        imageRect.origin.x = rect.size.width+rect.origin.x+3;
        imageRect.origin.y = (rect.size.height-imageRect.size.height)/2;
        imageRect.size.width = image.size.width/(image.size.height/imageRect.size.height);
        imageView.frame = imageRect;
        [titleView addSubview:imageView];
        
        CGRect titleFrame = CGRectMake(0, 0, 0, rect.size.height);
        titleFrame.size.width = imageRect.origin.x+imageRect.size.width;
        titleView.frame = titleFrame;
    }
    
    return titleView;
}

//添加动画遮罩 并在duration秒之后移除
- (void)addMaskViewWithDuration:(float)duration
{
    UIView *maskView = [[UIView alloc] initWithFrame:self.bounds];
    maskView.backgroundColor = [UIColor clearColor];
    [self addSubview:maskView];
    [maskView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:duration];
}


const char tapBlockKey;
const char tapGestureKey;

#pragma -mark TapGesture ( 注意： 必须使用weakSelf : __weak typeof(self) weakSelf = self; )
- (void)setTapActionWithBlock:(void (^)(void))block
{
    self.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *gesture = objc_getAssociatedObject(self, &tapGestureKey);
    if (!gesture){
        gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
        [self addGestureRecognizer:gesture];
        objc_setAssociatedObject(self, &tapGestureKey, gesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    objc_setAssociatedObject(self, &tapBlockKey, block, OBJC_ASSOCIATION_COPY);
}

- (void)tapGestureAction:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized){
        void(^action)(void) = objc_getAssociatedObject(self, &tapBlockKey);
        action ? action() : nil;
    }
}

const char panBlockKey;
const char panGestureKey;

- (void)setPanActionWithBlock:(void (^)(void))block
{
    self.userInteractionEnabled = YES;
    
    UIPanGestureRecognizer *gesture = objc_getAssociatedObject(self, &panGestureKey);
    if (!gesture){
        gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureAction:)];
        [self addGestureRecognizer:gesture];
        objc_setAssociatedObject(self, &panGestureKey, gesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    objc_setAssociatedObject(self, &panBlockKey, block, OBJC_ASSOCIATION_COPY);
}

- (void)swipeGestureAction:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized){
        void(^action)(void) = objc_getAssociatedObject(self, &panBlockKey);
        action ? action() : nil;
    }
}

/**
 *  autolayout强制更新界面大小
 */
- (void) sizeLayoutToFit
{
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
