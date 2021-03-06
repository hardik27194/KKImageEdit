//
//  KKPixellateEffect.m
//
//  Created by finger on 2015/10/23.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "KKPixellateEffect.h"

@implementation KKPixellateEffect
{
    UIView *_containerView;
    
    UISlider *_radiusSlider;
    
    CGFloat sliderValue ;
}

- (id)init
{
    self = [super init];
    
    if(self){
        sliderValue = 0.5 ;
    }
    
    return self;
}

- (id)initWithSuperView:(UIView*)superview
{
    self = [super init];
    
    if(self){
        
        _containerView = [[UIView alloc] initWithFrame:superview.bounds];
        [superview addSubview:_containerView];
        
        sliderValue = 0.5 ;
        
        _radiusSlider = [self sliderWithValue:sliderValue minimumValue:0 maximumValue:1.0];
        _radiusSlider.superview.center = CGPointMake(_containerView.frame.size.width / 2, _containerView.frame.size.height-30);
        
    }
    
    return self ;
}

- (void)cleanup
{
    [_containerView removeFromSuperview];
}

#pragma mark -- 效果调整滑块

- (UISlider*)sliderWithValue:(CGFloat)value minimumValue:(CGFloat)min maximumValue:(CGFloat)max
{
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10, 0, 260, 30)];
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, slider.frame.size.height)];
    container.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.3];
    container.layer.cornerRadius = slider.frame.size.height/2;
    
    slider.continuous = NO;
    [slider addTarget:self action:@selector(sliderDidChange:) forControlEvents:UIControlEventValueChanged];
    
    [slider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    
    slider.maximumValue = max;
    slider.minimumValue = min;
    slider.value = value;
    
    [container addSubview:slider];
    [_containerView addSubview:container];
    
    return slider;
}

- (void)sliderDidChange:(UISlider*)sender
{
    sliderValue = _radiusSlider.value ;
    
    [self.delegate effectParameterDidChange:self];
}

#pragma mark -- 应用效果

- (UIImage*)applyEffect:(UIImage*)image
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIPixellate" keysAndValues:kCIInputImageKey, ciImage, nil];
    [filter setDefaults];
    
    CGFloat R = MIN(image.size.width, image.size.height) * 0.1 * sliderValue;
    CIVector *vct = [[CIVector alloc] initWithX:image.size.width/2 Y:image.size.height/2];
    [filter setValue:vct forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithFloat:R] forKey:@"inputScale"];
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    CGRect clippingRect = [self clippingRectForTransparentSpace:cgImage];
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return [result clipImageInRect:clippingRect];
}

- (CGRect)clippingRectForTransparentSpace:(CGImageRef)inImage
{
    CGFloat left=0, right=0, top=0, bottom=0;
    
    CFDataRef m_DataRef = CGDataProviderCopyData(CGImageGetDataProvider(inImage));
    UInt8 * m_PixelBuf = (UInt8 *) CFDataGetBytePtr(m_DataRef);
    
    int width  = (int)CGImageGetWidth(inImage);
    int height = (int)CGImageGetHeight(inImage);
    
    BOOL breakOut = NO;
    for (int x = 0;breakOut==NO && x < width; ++x) {
        for (int y = 0; y < height; ++y) {
            int loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                left = x;
                breakOut = YES;
                break;
            }
        }
    }
    
    breakOut = NO;
    for (int y = 0;breakOut==NO && y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            int loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                top = y;
                breakOut = YES;
                break;
            }
            
        }
    }
    
    breakOut = NO;
    for (int y = height-1;breakOut==NO && y >= 0; --y) {
        for (int x = width-1; x >= 0; --x) {
            int loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                bottom = y;
                breakOut = YES;
                break;
            }
            
        }
    }
    
    breakOut = NO;
    for (int x = width-1;breakOut==NO && x >= 0; --x) {
        for (int y = height-1; y >= 0; --y) {
            int loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                right = x;
                breakOut = YES;
                break;
            }
            
        }
    }
    
    CFRelease(m_DataRef);
    
    return CGRectMake(left, top, right-left, bottom-top);
}

@end
