//
//  MCMenuLabel.h
//  MCFriends
//
//  Created by marujun on 14-6-11.
//  Copyright (c) 2014年 marujun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MCMenuLabel : UILabel

@property (nonatomic, assign) BOOL copyingEnabled; // Defaults to YES

// You may want to add longPressGestureRecognizer to a container view
@property (nonatomic, strong, readonly) UILongPressGestureRecognizer *longPressGestureRecognizer;

@end
