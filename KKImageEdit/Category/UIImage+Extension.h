//
//  UIImage+Scale.h
//  Apowersoft IOS AirMore
//
//  Created by wangxu on 15/4/9.
//  Copyright (c) 2015年 Joni. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage(Scale)

- (UIImage *)scaleToSize:(CGSize)size;
- (UIImage *)scaleToWidth:(CGFloat)width;
- (UIImage *)resize:(CGSize)size;

- (UIImage *)getImageApplyingAlpha:(float)theAlpha;

- (UIImage *)fixOrientationFromOrientation:(UIImageOrientation )fromImageOrientation;

- (UIImage *)scaleWithFactor:(float)scaleFloat quality:(CGFloat)compressionQuality;

- (UIImage*)aspectFit:(CGSize)size;
- (UIImage*)aspectFill:(CGSize)size;
- (UIImage*)aspectFill:(CGSize)size offset:(CGFloat)offset;

- (UIImage*)gaussBlur:(CGFloat)blurLevel;

- (UIImage*)maskedImage:(UIImage*)maskImage;

- (UIImage*)clipImageInRect:(CGRect)rect;

- (UIImage *)getThumbnailWithScaleSize:(CGSize)size;

@end
