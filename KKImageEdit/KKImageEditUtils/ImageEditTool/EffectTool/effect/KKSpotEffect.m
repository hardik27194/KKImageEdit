//
//  SpotEffect.m
//
//  Created by finger on 2015/10/23.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "KKSpotEffect.h"

@interface SpotCircle : UIView
{
}

@property (nonatomic, strong) UIColor *circleColor;

@end


#pragma mark -- UI components

@implementation SpotCircle

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [self setNeedsDisplay];
}

- (void)setCenter:(CGPoint)center
{
    [super setCenter:center];
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, self.circleColor.CGColor);
    CGContextStrokeEllipseInRect(context, self.bounds);
    
    self.alpha = 1;
    [UIView animateWithDuration:0.2 delay:1 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.alpha = 0;
    }completion:^(BOOL finished) {
    }];
}

@end

@interface KKSpotEffect()<UIGestureRecognizerDelegate>
{
    UIView *_containerView;
    SpotCircle *_circleView;
    
    CGFloat _X;
    CGFloat _Y;
    CGFloat _R;
}

@end

@implementation KKSpotEffect

- (id)init
{
    self = [super init];
    
    if(self){
        
        _X = 0.5;
        _Y = 0.5;
        _R = 0.5;
        
    }
    
    return self ;
}

- (id)initWithSuperView:(UIView*)superView
{
    self = [super init];
    
    if(self){
        
        _containerView = [[UIView alloc] initWithFrame:superView.bounds];
        [superView addSubview:_containerView];
        
        _X = 0.5;
        _Y = 0.5;
        _R = 0.5;
        
        [self setUserInterface];
    }
    
    return self;
}

- (void)cleanup
{
    [_containerView removeFromSuperview];
}

#pragma mark -- 加载圆圈视图

- (void)setUserInterface
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapContainerView:)];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panContainerView:)];
    UIPinchGestureRecognizer *pinch    = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchContainerView:)];
    
    pan.maximumNumberOfTouches = 1;
    
    [_containerView addGestureRecognizer:tap];
    [_containerView addGestureRecognizer:pan];
    [_containerView addGestureRecognizer:pinch];
    
    _circleView = [[SpotCircle alloc] init];
    _circleView.backgroundColor = [UIColor clearColor];
    _circleView.circleColor = [UIColor redColor];
    [_containerView addSubview:_circleView];
    
    [self drawCircleView];
}

- (void)drawCircleView
{
    CGFloat R = MIN(_containerView.frame.size.width, _containerView.frame.size.height) * (_R + 0.1) * 1.2;
    
    CGRect frame = _circleView.frame ;
    frame.size.width  = R ;
    frame.size.height = R ;
    _circleView.frame = frame ;
    
    _circleView.center = CGPointMake(_containerView.frame.size.width * _X, _containerView.frame.size.height * _Y);
    
    [_circleView setNeedsDisplay];
}

- (void)tapContainerView:(UITapGestureRecognizer*)sender
{
    CGPoint point = [sender locationInView:_containerView];
    _X = MIN(1.0, MAX(0.0, point.x / _containerView.frame.size.width));
    _Y = MIN(1.0, MAX(0.0, point.y / _containerView.frame.size.height));
    
    [self drawCircleView];
    
    if (sender.state == UIGestureRecognizerStateEnded){
        [self.delegate effectParameterDidChange:self];
    }
}

- (void)panContainerView:(UIPanGestureRecognizer*)sender
{
    CGPoint point = [sender locationInView:_containerView];
    _X = MIN(1.0, MAX(0.0, point.x / _containerView.frame.size.width));
    _Y = MIN(1.0, MAX(0.0, point.y / _containerView.frame.size.height));
    
    [self drawCircleView];
    
    if (sender.state == UIGestureRecognizerStateEnded){
        [self.delegate effectParameterDidChange:self];
    }
}

- (void)pinchContainerView:(UIPinchGestureRecognizer*)sender
{
    static CGFloat initialScale;
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        initialScale = (_R + 0.1);
    }
    
    _R = MIN(1.1, MAX(0.1, initialScale * sender.scale)) - 0.1;
    
    [self drawCircleView];
    
    if (sender.state == UIGestureRecognizerStateEnded){
        [self.delegate effectParameterDidChange:self];
    }
}

#pragma mark -- 应用效果

- (UIImage*)applyEffect:(UIImage*)image
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIVignetteEffect" keysAndValues:kCIInputImageKey, ciImage, nil];
    [filter setDefaults];
    
    CGFloat R = MIN(image.size.width, image.size.height) * image.scale * 0.5 * (_R + 0.1);
    CIVector *vct = [[CIVector alloc] initWithX:image.size.width * image.scale * _X Y:image.size.height * image.scale * (1 - _Y)];
    [filter setValue:vct forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithFloat:R] forKey:@"inputRadius"];
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

@end
