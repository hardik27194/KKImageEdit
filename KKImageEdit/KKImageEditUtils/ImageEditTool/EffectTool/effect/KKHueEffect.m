//
//  KKHueEffect.m
//
//  Created by finger on 2015/10/23.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "KKHueEffect.h"

@interface KKHueEffect()
{
    UIView *_containerView;
    
    UISlider *_radiusSlider;
    
    CGFloat sliderValue ;
}

@end

@implementation KKHueEffect

- (id)init
{
    self = [super init];
    
    if(self){
        sliderValue = 0 ;
    }
    
    return self;
}

- (id)initWithSuperView:(UIView*)superview
{
    self = [super init];
    
    if(self){
        
        _containerView = [[UIView alloc] initWithFrame:superview.bounds];
        [superview addSubview:_containerView];
        
        sliderValue = 0 ;
        
        _radiusSlider = [self sliderWithValue:sliderValue minimumValue:-M_PI maximumValue:M_PI];
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
    CIFilter *filter = [CIFilter filterWithName:@"CIHueAdjust" keysAndValues:kCIInputImageKey, ciImage, nil];
    
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:sliderValue] forKey:@"inputAngle"];
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

@end
