//
//  MCMenuLabel.m
//  MCFriends
//
//  Created by marujun on 14-6-11.
//  Copyright (c) 2014年 marujun. All rights reserved.
//

#import "MCMenuLabel.h"

@implementation MCMenuLabel

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup
{
    self.userInteractionEnabled = YES;
    _copyingEnabled = YES;
    
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:_longPressGestureRecognizer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideEditMenu:) name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

- (void)setCopyingEnabled:(BOOL)copyingEnabled
{
    if (_copyingEnabled != copyingEnabled)
    {
        _copyingEnabled = copyingEnabled;
        
        self.userInteractionEnabled = copyingEnabled;
        _longPressGestureRecognizer.enabled = copyingEnabled;
    }
}

#pragma mark - Callbacks

- (void)willHideEditMenu:(NSNotification *)note
{
    [UIView animateWithDuration:.3 animations:^{
        self.backgroundColor = [UIColor clearColor];
    }];
}

- (void)longPress:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [recognizer.view becomeFirstResponder];
        
        UIMenuController *copyMenu = [UIMenuController sharedMenuController];
        UIMenuItem *copyItem = [[UIMenuItem alloc] initWithTitle:@"复制"action:@selector(copyAction:)];
        [copyMenu setMenuItems:[NSArray arrayWithObjects:copyItem, nil]];
        [copyMenu setTargetRect:recognizer.view.bounds inView:recognizer.view];
        [copyMenu setMenuVisible:YES animated:YES];
        
        [UIView animateWithDuration:.3 animations:^{
            self.backgroundColor = HexColor(0xe8e8e8);
        }];
    }
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder
{
    return true;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(copyAction:)){
        return YES;
	}
    return NO;
}

- (void)copyAction:(id)sender
{
    [[UIPasteboard generalPasteboard] setString:self.text];
}


@end
