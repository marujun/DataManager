//
//  USNavDelegateHandler.h
//  USNavAnimation
//
//  Created by marujun on 15/12/26.
//  Copyright © 2015年 MaRuJun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface USNavDelegateHandler : UIView <UINavigationControllerDelegate,UIGestureRecognizerDelegate>

@property (strong, nonatomic) UINavigationController *navigationController;

@end
