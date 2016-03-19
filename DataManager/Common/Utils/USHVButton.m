//
//  USHVButton.m
//  HappyIn
//
//  Created by marujun on 16/3/2.
//  Copyright © 2016年 MaRuJun. All rights reserved.
//

#import "USHVButton.h"

@implementation USHVButton

//code
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self makeEdgeHighlighted:self.highlighted];
    }
    return self;
}

//XIB
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self makeEdgeHighlighted:self.highlighted];
    }
    return self;
}

- (void)setSpace:(CGFloat)space
{
    _space = space;
    
    [self makeEdgeHighlighted:self.highlighted];
}

- (void)setImage_size:(CGSize)image_size
{
    _image_size = image_size;
    
    [self setImageSize:_image_size forState:UIControlStateNormal];
    [self setImageSize:_image_size forState:UIControlStateHighlighted];
    [self setImageSize:_image_size forState:UIControlStateSelected];
}

- (void)setImageSize:(CGSize)size forState:(UIControlState)state
{
    UIImage *oldImage = [self imageForState:state];
    
    if (oldImage && !CGSizeEqualToSize(oldImage.size, size)) {
        [self setImage:[oldImage imageScaledToSize:size] forState:state];
    }
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state
{
    UIImage *oldImage = [self imageForState:state];
    
    [super setImage:image forState:state];
    
    if (!oldImage || !CGSizeEqualToSize(oldImage.size, image.size)) {
        [self makeEdgeHighlighted:self.highlighted];
    }
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
    [super setTitle:title forState:state];
    
    [self makeEdgeHighlighted:self.highlighted];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [self makeEdgeHighlighted:self.highlighted];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    [self makeEdgeHighlighted:highlighted];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    [self makeEdgeHighlighted:self.highlighted];
}

- (void)makeEdgeHighlighted:(BOOL)highlighted
{
    [self setTitleEdgeInsets:UIEdgeInsetsZero];
    [self setImageEdgeInsets:UIEdgeInsetsZero];
    
    NSString *_text;
    UIImage *_image;
    
    if (highlighted) {
        _text = [self titleForState:UIControlStateHighlighted];
        _image = [self imageForState:UIControlStateHighlighted];
    }
    else if (self.selected){
        _text = [self titleForState:UIControlStateSelected];
        _image = [self imageForState:UIControlStateSelected];
    }
    else{
        _text = [self titleForState:UIControlStateNormal];
        _image = [self imageForState:UIControlStateNormal];
    }
    
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    
    CGFloat btnWidth = self.bounds.size.width;
    CGFloat btnHeight = self.bounds.size.height;
    
    CGFloat imgHeight = _image.size.height;
    
    CGFloat imgCenterX = self.imageView.center.x;
    
    CGFloat textHeight = self.titleLabel.bounds.size.height;
    CGSize  size = [self sizeWithFont:self.titleLabel.font
                    constrainedToSize:CGSizeMake(CGFLOAT_MAX, textHeight)
                                 text:_text];
    
    CGFloat textCenterX = size.width/2 + self.titleLabel.frame.origin.x;
    
    CGFloat top = (btnHeight - (imgHeight + self.space + textHeight)) / 2;
    
    [self setImageEdgeInsets:UIEdgeInsetsMake(top, (btnWidth / 2 - imgCenterX), 0, 0)];
    [self setTitleEdgeInsets:UIEdgeInsetsMake(imgHeight + self.space + top, (btnWidth / 2 - textCenterX), 0, 0)];
}

- (CGSize)sizeWithFont:(UIFont*)tFont constrainedToSize:(CGSize)consize text:(NSString *)text
{
    if (!(text.length > 0)) {
        text = @"";
    }
    
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:text
                                                                  attributes:@{NSFontAttributeName:tFont}];
    return [attrStr boundingRectWithSize:consize
                                 options:NSStringDrawingUsesLineFragmentOrigin
                                 context:nil].size;
}


@end
