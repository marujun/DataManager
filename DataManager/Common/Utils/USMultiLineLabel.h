//
//  USMultiLineLabel.h
//  USEvent
//
//  Created by marujun on 15/11/30.
//  Copyright © 2015年 MaRuJun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface USMultiLineLabel : UILabel
{
@private
    long      characterSpacing_;       //字间距
    CGFloat   linesSpacing_;           //行间距
}

@property(nonatomic, assign) long      characterSpacing;
@property(nonatomic, assign) CGFloat   linesSpacing;

/** 绘制前获取label高度和最小宽度 */
- (CGSize)sizeWithAttributedStringWidth:(CGFloat)width;

@end
