//
//  UIImage+Common.m
//  HLMagic
//
//  Created by marujun on 13-12-8.
//  Copyright (c) 2013年 chen ying. All rights reserved.
//

#import "UIImage+Common.h"
#import <Accelerate/Accelerate.h>

CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
CGFloat RadiansToDegrees(CGFloat radians) {return radians * 180/M_PI;};

@implementation UIImage (Common)

+ (UIImage *)screenshot
{
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, [UIScreen mainScreen].scale);
    
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
    return [self imageWithColor:color size:CGSizeMake(4, 4)];
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 1, 1)];;
}

+ (UIImage *)imageWithColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius
{
    CGFloat minEdgeSize = cornerRadius * 2 + 1;
    CGRect rect = CGRectMake(0, 0, minEdgeSize, minEdgeSize);
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
    roundedRect.lineWidth = 0;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
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
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *resImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return resImage;
}

- (UIImage *)imageScaledToSize:(CGSize)newSize
{
    newSize.width = (int)newSize.width;
    newSize.height = (int)newSize.height;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1);
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

- (UIImage *)imageRotatedByRadians:(CGFloat)radians
{
    return [self imageRotatedByDegrees:RadiansToDegrees(radians)];
}

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees
{
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.size.width, self.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(degrees));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, DegreesToRadians(degrees));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

//模糊化图片
- (UIImage *)imageBluredByRadius:(CGFloat)radius
{
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
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(cgImage);
    
    return image;
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
    
    return [UIImage imageWithCIImage:outputImage scale:self.scale orientation:self.imageOrientation];
}

//灰度化图片
- (UIImage *)grayscaleImage
{
    CGRect imageRect = CGRectMake(0, 0, self.size.width, self.size.height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(nil, self.size.width, self.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
    CGContextDrawImage(context, imageRect, [self CGImage]);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    
    return newImage;
}

- (UIImage *)invertColor
{
    CIImage *coreImage = [CIImage imageWithCGImage:[self CGImage]];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    [filter setValue:coreImage forKey:kCIInputImageKey];
    
    CIImage *outputImage = [filter valueForKey:kCIOutputImageKey];
    
    return [UIImage imageWithCIImage:outputImage scale:self.scale orientation:self.imageOrientation];
}


//修正图片方向
- (UIImage *)fixOrientation
{
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    // The UIImage methods size and drawInRect take into account
    //  the value of its imageOrientation property
    //  so the rendered image is rotated as necessary.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    
    UIImage *orientedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return orientedImage;
}

//反转后的遮罩图片
- (UIImage *)inverseMaskImage
{
    UIImage *image = [UIImage imageWithColor:[UIColor blackColor] size:self.size];
    
    CGImageRef maskRef = self.CGImage;
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef sourceImage = [image CGImage];
    CGImageRef imageWithAlpha = sourceImage;
    //add alpha channel for images that don't have one (ie GIF, JPEG, etc...)
    //this however has a computational cost
    if (CGImageGetAlphaInfo(sourceImage) == kCGImageAlphaNone) {
        //copyImageAndAddAlphaChannel
        CGImageRef retVal = NULL;
        
        size_t width = CGImageGetWidth(sourceImage);
        size_t height = CGImageGetHeight(sourceImage);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef offscreenContext = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace,
                                                              kCGImageAlphaPremultipliedFirst);
        if (offscreenContext != NULL) {
            CGContextDrawImage(offscreenContext, CGRectMake(0, 0, width, height), sourceImage);
            retVal = CGBitmapContextCreateImage(offscreenContext);
            CGContextRelease(offscreenContext);
        }
        CGColorSpaceRelease(colorSpace);
        imageWithAlpha = retVal;
    }
    
    CGImageRef masked = CGImageCreateWithMask(imageWithAlpha, mask);
    CGImageRelease(mask);
    
    //release imageWithAlpha if it was created by CopyImageAndAddAlphaChannel
    if (sourceImage != imageWithAlpha) {
        CGImageRelease(imageWithAlpha);
    }
    
    UIImage *retImage = [UIImage imageWithCGImage:masked scale:self.scale orientation:self.imageOrientation];
    
    CGImageRelease(masked);
    
    return retImage;
}

@end
