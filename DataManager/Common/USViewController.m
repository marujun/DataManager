//
//  USViewController.m
//  USEvent
//
//  Created by marujun on 15/9/8.
//  Copyright (c) 2015年 MaRuJun. All rights reserved.
//

#import "USViewController.h"

@interface USViewController ()

@end


@implementation USViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self fInit];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    NSShadow *shadow = [NSShadow new];
    NSDictionary *dict = @{NSShadowAttributeName:shadow};
    
    self.navigationBar.clipsToBounds = YES;
    self.navigationBar.translucent = NO;
    self.navigationBar.titleTextAttributes = dict;
    self.navigationBar.barTintColor = [UIColor whiteColor];
    
    if (self.navigationController) {
        self.navigationController.navigationBar.clipsToBounds = YES;
        self.navigationController.navigationBar.translucent = NO;
        self.navigationController.navigationBar.titleTextAttributes = dict;
        self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
        [self.navigationController.navigationBar setTitleVerticalPositionAdjustment:-2 forBarMetrics:UIBarMetricsDefault];
    }
    
    [self.view addSubview:self.navigationBar];
    [self.navigationBar pushNavigationItem:self.myNavigationItem animated:NO];
    [self.navigationBar autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, -1, 0, 0) excludingEdge:ALEdgeBottom];
}

- (void)setTitle:(NSString *)title
{
    self.myNavigationItem.title = title;
    
    [super setTitle:title];
}

- (void)fInit
{
    _topInset = 64;
    _enableScreenEdgePanGesture = YES;
    self.navigationBar = [[UINavigationBar alloc] initForAutoLayout];
    [self.navigationBar autoSetDimension:ALDimensionHeight toSize:_topInset];
    
    self.myNavigationItem = [[UINavigationItem alloc] initWithTitle:@""];
    [self.navigationBar setTitleVerticalPositionAdjustment:-2.f forBarMetrics:UIBarMetricsDefault];
    
    FLOG(@"init 创建类 %@", NSStringFromClass([self class]));
}

- (void)updateDisplay
{
    
}

- (UIViewController *)viewControllerWillPushForLeftDirectionPan
{
    return nil;
}

+ (instancetype)viewController
{
    return [[self alloc] initWithNibName:NSStringFromClass([self class]) bundle:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self UMStatisticPage]) {
//        [MobClick beginLogPageView:[self UMStatisticPage]];
    }
    
    [[ImageCacheManager defaultManager] bringIdentifyToFront:NSStringFromClass([self class])];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self UMStatisticPage]) {
//        [MobClick endLogPageView:[self UMStatisticPage]];
    }
}



//友盟页面统计
- (NSString *)UMStatisticPage
{
#ifdef DEBUG
    return nil;
#else
    NSString *className = NSStringFromClass([self class]);
    
    if ([className isEqualToString:@"USHomeViewController"]) {
        return @"首页";
    }
    
    return nil;
#endif
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    FLOG(@"dealloc 释放类 %@",  NSStringFromClass([self class]));
}

@end
