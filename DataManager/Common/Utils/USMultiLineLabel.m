//
//  USMultiLineLabel.m
//  USEvent
//
//  Created by marujun on 15/11/30.
//  Copyright © 2015年 MaRuJun. All rights reserved.
//

#import "USMultiLineLabel.h"
#import<CoreText/CoreText.h>

@interface USMultiLineLabel()
{
@private
    NSMutableAttributedString *attributedString;
}
- (void) initAttributedString;
@end


@implementation USMultiLineLabel

@synthesize characterSpacing = characterSpacing_;
@synthesize linesSpacing = linesSpacing_;

- (id)initWithFrame:(CGRect)frame
{
    //初始化字间距、行间距
    self = [super initWithFrame:frame];
    if (self) {
        self.characterSpacing = 1.0f;
        self.linesSpacing = 4.4f;
    }
    return self;
}

//外部调用设置字间距
- (void)setCharacterSpacing:(long)characterSpacing
{
    characterSpacing_ = characterSpacing;
    [self setNeedsDisplay];
}

//外部调用设置行间距
- (void)setLinesSpacing:(CGFloat)linesSpacing
{
    linesSpacing_ = linesSpacing;
    [self setNeedsDisplay];
}

/*
 * 初始化AttributedString并进行相应设置
 */
- (void)initAttributedString
{
    if(!attributedString || ![attributedString.string isEqualToString:self.text]){
        //去掉空行
        NSString *labelString = self.text;
        NSString *myString = [labelString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
        
        //创建AttributeString
        attributedString = [[NSMutableAttributedString alloc] initWithString:myString];
        
        //设置字体及大小
        CTFontRef helveticaBold = CTFontCreateWithName((CFStringRef)self.font.fontName, self.font.pointSize, NULL);
        [attributedString addAttribute:(id)kCTFontAttributeName value:(__bridge id)helveticaBold range:NSMakeRange(0,[attributedString length])];
        
        //设置字间距
        long number = self.characterSpacing;
        
        CFNumberRef num = CFNumberCreate(kCFAllocatorDefault,kCFNumberSInt8Type,&number);
        [attributedString addAttribute:(id)kCTKernAttributeName value:(__bridge id)num range:NSMakeRange(0,[attributedString length])];
        CFRelease(num);
        
        //设置字体颜色
        [attributedString addAttribute:(id)kCTForegroundColorAttributeName value:(id)(self.textColor.CGColor) range:NSMakeRange(0,[attributedString length])];
        
        //创建文本对齐方式
        CTTextAlignment alignment = kCTLeftTextAlignment;
        if(self.textAlignment == NSTextAlignmentCenter)
        {
            alignment = kCTCenterTextAlignment;
        }
        if(self.textAlignment == NSTextAlignmentRight)
        {
            alignment = kCTRightTextAlignment;
        }
        
        CTParagraphStyleSetting alignmentStyle;
        
        alignmentStyle.spec = kCTParagraphStyleSpecifierAlignment;
        
        alignmentStyle.valueSize = sizeof(alignment);
        
        alignmentStyle.value = &alignment;
        
        //设置文本行间距
        CGFloat lineSpace = self.linesSpacing;
        
        CTParagraphStyleSetting lineSpaceStyle;
        lineSpaceStyle.spec = kCTParagraphStyleSpecifierLineSpacingAdjustment;
        lineSpaceStyle.valueSize = sizeof(lineSpace);
        lineSpaceStyle.value =&lineSpace;
        
        //设置文本段间距
        CGFloat paragraphSpacing = 15.0;
        CTParagraphStyleSetting paragraphSpaceStyle;
        paragraphSpaceStyle.spec = kCTParagraphStyleSpecifierParagraphSpacing;
        paragraphSpaceStyle.valueSize = sizeof(CGFloat);
        paragraphSpaceStyle.value = &paragraphSpacing;
        
        //创建设置数组
        CTParagraphStyleSetting settings[ ] ={alignmentStyle,lineSpaceStyle,paragraphSpaceStyle};
        CTParagraphStyleRef style = CTParagraphStyleCreate(settings ,3);
        
        //给文本添加设置
        [attributedString addAttribute:(id)kCTParagraphStyleAttributeName value:(__bridge id)style range:NSMakeRange(0 , [attributedString length])];
        CFRelease(helveticaBold);
    }
}


/*
 * 覆写setText方法
 */
- (void) setText:(NSString *)text
{
    [super setText:text];
    [self initAttributedString];
}

/*
 * 开始绘制
 */
- (void) drawTextInRect:(CGRect)requestedRect
{
    [self initAttributedString];
    
    //排版
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributedString);
    
    CGMutablePathRef leftColumnPath = CGPathCreateMutable();
    
    CGPathAddRect(leftColumnPath, NULL ,CGRectMake(0 , 0 ,self.bounds.size.width , self.bounds.size.height));
    
    CTFrameRef leftFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0, 0), leftColumnPath , NULL);
    
    //翻转坐标系统（文本原来是倒的要翻转下）
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetTextMatrix(context , CGAffineTransformIdentity);
    
    CGContextTranslateCTM(context , 0 ,self.bounds.size.height);
    
    CGContextScaleCTM(context, 1.0 ,-1.0);
    
    //画出文本
    
    CTFrameDraw(leftFrame,context);
    
    //释放
    
    CGPathRelease(leftColumnPath);
    
    CFRelease(framesetter);
    
    UIGraphicsPushContext(context);
}


/*
 * 绘制前获取label高度和最小宽度
 */
- (CGSize)sizeWithAttributedStringWidth:(CGFloat)width
{
    [self initAttributedString];
    
    CGFloat min_width = 0;
    int total_height = 0;
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributedString);    //string 为要计算高度的NSAttributedString
    CGRect drawingRect = CGRectMake(0, 0, width, 100000);  //这里的高要设置足够大
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, drawingRect);
    CTFrameRef textFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0,0), path, NULL);
    CGPathRelease(path);
    CFRelease(framesetter);
    
    NSArray *lines = (NSArray *) CTFrameGetLines(textFrame);
    
    if (lines.count) {
        if(lines.count > 1){
            min_width = self.width;
        } else {
            CTLineRef line = (__bridge CTLineRef)lines[0];
            min_width = CTLineGetTypographicBounds(line, nil, nil, nil);
        }
        
        CGPoint origins[[lines count]];
        CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);
        
        int line_y = (int) origins[[lines count] -1].y;  //最后一行line的原点y坐标
        
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        
        CTLineRef line = (__bridge CTLineRef) [lines objectAtIndex:[lines count]-1];
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        
        total_height = 100000 - line_y + (int) descent +1;//+1为了纠正descent转换成int小数点后舍去的值
    }
    
    CFRelease(textFrame);
    
    return CGSizeMake(min_width, total_height);
}

@end