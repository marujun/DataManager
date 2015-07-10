//
//  UIImage+Common.m
//  HLMagic
//
//  Created by marujun on 13-12-8.
//  Copyright (c) 2013年 chen ying. All rights reserved.
//

#import "UIImage+Common.h"
#import <Accelerate/Accelerate.h>

@implementation UIImage (Common)

+ (UIImage *)screenshot
{
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
            CGContextSaveGState(context);
            
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            
            CGContextConcatCTM(context, [window transform]);
            
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
            
            [[window layer] renderInContext:context];
            
            CGContextRestoreGState(context);
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)imageWithColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius
{
    CGFloat minEdgeSize = cornerRadius * 2 + 1;
    CGRect rect = CGRectMake(0, 0, minEdgeSize, minEdgeSize);
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
    roundedRect.lineWidth = 0;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    [color setFill];
    [roundedRect fill];
    [roundedRect stroke];
    [roundedRect addClip];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius)];
}

//UIView转换为UIImage
+ (UIImage *)imageWithView:(UIView *)view
{
    //支持retina高分的关键
    if(&UIGraphicsBeginImageContextWithOptions != NULL){
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);
    } else {
        UIGraphicsBeginImageContext(view.bounds.size);
    }
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *resImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return resImage;
}

- (UIImage *)imageScaledToSize:(CGSize)newSize
{
    newSize.width = (int)newSize.width;
    newSize.height = (int)newSize.height;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)squareImage
{
    CGSize imgSize = self.size;
    if (imgSize.width !=  imgSize.height) {
        CGFloat image_x =0.0;
        CGFloat image_y =0.0;
        UIImage *image = nil;
        if (imgSize.width >  imgSize.height) {
            image_x = (imgSize.width -imgSize.height)/2;
            image = [self imageClipedWithRect:CGRectMake(image_x, 0, imgSize.height, imgSize.height)];
        }else{
            image_y = (imgSize.height -imgSize.width)/2;
            image = [self imageClipedWithRect:CGRectMake(0,image_y, imgSize.width, imgSize.width)];
        }
        return image;
    }
    return self;
}

- (UIImage *)imageClipedWithRect:(CGRect)clipRect
{
    CGImageRef imageRef = self.CGImage;
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, clipRect);

    UIGraphicsBeginImageContext(clipRect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, clipRect, subImageRef);
    UIImage* clipImage = [UIImage imageWithCGImage:subImageRef];
    CGImageRelease(subImageRef);
    UIGraphicsEndImageContext();
    
    return clipImage;
}

+ (UIImage *)defaultImage
{
    return [UIImage imageNamed:@"default_default_loading.jpg"];
}

+ (UIImage *)defaultAvatar
{
    return [UIImage imageNamed:@"pub_default_avatar.jpg"];
}

+ (UIImage *)defaultBigAvatar
{
    return [UIImage imageNamed:@"pub_big_default_avatar.jpg"];
}


//圆形的头像图片
- (UIImage *)circleAvatarImage
{
    // when an image is set for the annotation view,
    // it actually adds the image to the image view
    
    //圆环宽度
    float annulusLen = 5;
    //边框宽度
    float borderWidth = 2;
    
    float fixWidth = self.size.width;
    
    float radius1 = fixWidth / 2;
    float radius2 = radius1 + borderWidth;
    float radius3 = radius2 + annulusLen;
    
    CGSize canvasSize = CGSizeMake(radius3 * 2, radius3 * 2);
    
    UIGraphicsBeginImageContext(canvasSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //抗锯齿
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetShouldAntialias(context, true);
    
    // Create the gradient's colours
    float start = 0;
    float end = 0;
    
	size_t num_locations = 2;
	CGFloat locations[2] = { 0.0, 1.0 };
	CGFloat components[8] = { start,start,start, 0.5,  // Start color
        end,end,end, 0 }; // End color
	
	CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef myGradient = CGGradientCreateWithColorComponents (myColorspace, components, locations, num_locations);
    CGPoint centerPoint = CGPointMake(radius3, radius3);
	// Draw it!
	CGContextDrawRadialGradient (context, myGradient, centerPoint, radius2, centerPoint, radius3, kCGGradientDrawsAfterEndLocation);
    
    // draw outline so that the edges are smooth:
    // set line width
    CGContextSetLineWidth(context, 1);
    // set the colour when drawing lines R,G,B,A. (we will set it to the same colour we used as the start and end point of our gradient )
    
    //描边 抗锯齿
    CGContextSetRGBStrokeColor(context, start, start, start, 0.5);
    CGContextAddEllipseInRect(context, CGRectMake(annulusLen, annulusLen, radius2 * 2, radius2 * 2));
    CGContextStrokePath(context);
    
    CGContextSetRGBStrokeColor(context, end, end, end, 0);
    CGContextAddEllipseInRect(context, CGRectMake(0, 0, radius3 * 2, radius3 * 2));
    CGContextStrokePath(context);
    
    //--------------------------
    
    float borderGap = radius3 - radius1 - borderWidth / 2;
    UIColor *color = [UIColor whiteColor];
    if (borderWidth > 0) {
        CGContextSetStrokeColorWithColor(context, color.CGColor);
        CGContextSetLineCap(context,kCGLineCapButt);
        CGContextSetLineWidth(context, borderWidth);
        CGContextAddEllipseInRect(context, CGRectMake(borderGap, borderGap, radius2 * 2 - borderWidth, radius2 * 2 - borderWidth));//在这个框中画圆
        
        CGContextStrokePath(context);
    }
    
    float imageGap = radius3 - radius1;
    CGRect rect = CGRectMake(imageGap, imageGap, fixWidth , fixWidth);
    CGContextAddEllipseInRect(context, rect);
    CGContextClip(context);
    [self drawInRect:rect];
    
    UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGColorSpaceRelease(myColorspace);
    CGGradientRelease(myGradient);
    
    return newimg;
}

//模糊化图片
- (UIImage *)bluredImageWithRadius:(CGFloat)radius
{
    //TODO:  requires iOS 6
    
    //create our blurred image
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:self.CGImage];
    
    //setting up Gaussian Blur (we could use one of many filters offered by Core Image)
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:radius] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    //CIGaussianBlur has a tendency to shrink the image a little, this ensures it matches up exactly to the bounds of our original image
    CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];
    
    return [UIImage imageWithCGImage:cgImage];
}

//黑白图片
- (UIImage*)monochromeImage
{
    CIImage *beginImage = [CIImage imageWithCGImage:[self CGImage]];
    
    CIColor *ciColor = [CIColor colorWithCGColor:[UIColor lightGrayColor].CGColor];
    CIFilter *filter = nil;
    CIImage *outputImage;
    filter = [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:kCIInputImageKey, beginImage, kCIInputColorKey, ciColor, nil];
    outputImage = [filter outputImage];
    
    [EAGLContext setCurrentContext:nil];

    return  [UIImage imageWithCIImage:outputImage];
}


@end
