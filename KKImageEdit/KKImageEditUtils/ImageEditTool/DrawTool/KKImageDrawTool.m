//
//  DrawTool.m
//
//  Created by finger on 2014/06/20.
//  Copyright (c) 2014年 finger. All rights reserved.
//

#import "KKImageDrawTool.h"
#import "UIImage+Extension.h"

#define MAX_DRAW_WIDTH 40

@implementation KKImageDrawTool
{
    CGPoint _prevDraggingPosition;
    
    UIImageView *_eraserIcon;
    
    UIView *_contentView ;
    UIImageView *_drawingView;
    
    UIView *_menuView;
    UISlider *_colorSlider;
    UISlider *_widthSlider;
    UIView *_strokePreview;
    UIView *_strokePreviewBackground;
    
    //放大镜
    UIView *_magnifierView ;
    UIImageView *_magnifierImageView;
    UIView *_circleView;
    
    UIImage *_originalImage ;
}

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image
{
    _originalImage = image ;
    
    _contentView = [[UIView alloc]initWithFrame:view.bounds];
    [view addSubview:_contentView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drawingViewDidPan:)];
    panGesture.maximumNumberOfTouches = 1;
    _drawingView = [[UIImageView alloc] initWithFrame:frame];
    _drawingView.userInteractionEnabled = YES;
    [_drawingView addGestureRecognizer:panGesture];
    [_contentView addSubview:_drawingView];
    
    _magnifierView = [[UIView alloc]initWithFrame:CGRectMake(5, 5, MAX_DRAW_WIDTH+10, MAX_DRAW_WIDTH+10)];
    _magnifierView.layer.cornerRadius = 5 ;
    _magnifierView.layer.borderColor = [[UIColor whiteColor]CGColor];
    _magnifierView.layer.borderWidth = 1 ;
    _magnifierView.clipsToBounds = YES ;
    _magnifierView.hidden = YES ;
    [_drawingView addSubview:_magnifierView];
    
    _magnifierImageView = [[UIImageView alloc]initWithFrame:_magnifierView.bounds];
    [_magnifierView addSubview:_magnifierImageView];
    
    int w = MIN(MAX_DRAW_WIDTH,MAX(10, _widthSlider.value * MAX_DRAW_WIDTH));
    _circleView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, w, w)];
    _circleView.clipsToBounds = YES ;
    _circleView.layer.cornerRadius = _circleView.frame.size.height/2 ;
    _circleView.layer.borderWidth = 1 ;
    _circleView.layer.borderColor = [[UIColor redColor]CGColor];
    _circleView.center = CGPointMake(_magnifierView.center.x-_magnifierView.frame.origin.x,_magnifierView.center.y-_magnifierView.frame.origin.y) ;
    [_magnifierView addSubview:_circleView];
    
    _menuView = [[UIView alloc] initWithFrame:menuView.bounds];
    _menuView.backgroundColor = [UIColor blackColor];
    [menuView addSubview:_menuView];
    
    _menuView.transform = CGAffineTransformMakeTranslation(0, _menuView.frame.size.height);
    [UIView animateWithDuration:0.3 animations:^{
        _menuView.transform = CGAffineTransformIdentity;
    }];
    
    [self setMenu];
    [self colorSliderDidChange:_colorSlider];
    [self widthSliderDidChange:_widthSlider];
}

- (void)cleanup
{
    [_circleView removeFromSuperview];
    [_magnifierImageView removeFromSuperview];
    [_magnifierView removeFromSuperview];
    
    [_drawingView removeFromSuperview];
    [_contentView removeFromSuperview];
    
    [UIView animateWithDuration:0.3 animations:^{
        _menuView.transform = CGAffineTransformMakeTranslation(0, _menuView.frame.size.height);
    }completion:^(BOOL finished) {
        [_menuView removeFromSuperview];
    }];
}

#pragma mark -- 滑动条

- (UISlider*)defaultSliderWithWidth:(CGFloat)width
{
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
    
    [slider setMaximumTrackImage:[UIImage new] forState:UIControlStateNormal];
    [slider setMinimumTrackImage:[UIImage new] forState:UIControlStateNormal];
    [slider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    
    return slider;
}

- (UIImage*)colorSliderBackground
{
    CGSize size = _colorSlider.frame.size;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect frame = CGRectMake(5, (size.height-10)/2, size.width-10, 5);
    CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:5].CGPath;
    CGContextAddPath(context, path);
    CGContextClip(context);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {
        0.0f, 0.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 1.0f, 1.0f,
        1.0f, 0.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 0.0f, 1.0f,
        0.0f, 1.0f, 0.0f, 1.0f,
        0.0f, 1.0f, 1.0f, 1.0f,
        0.0f, 0.0f, 1.0f, 1.0f
    };
    
    size_t count = sizeof(components)/ (sizeof(CGFloat)* 4);
    CGFloat locations[] = {0.0f, 0.9/3.0, 1/3.0, 1.5/3.0, 2/3.0, 2.5/3.0, 1.0};
    
    CGPoint startPoint = CGPointMake(5, 0);
    CGPoint endPoint = CGPointMake(size.width-5, 0);
    
    CGGradientRef gradientRef = CGGradientCreateWithColorComponents(colorSpaceRef, components, locations, count);
    
    CGContextDrawLinearGradient(context, gradientRef, startPoint, endPoint, kCGGradientDrawsAfterEndLocation);
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradientRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

- (UIImage*)widthSliderBackground
{
    CGSize size = _widthSlider.frame.size;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *color = [UIColor redColor];
    
    CGFloat strRadius = 1;
    CGFloat endRadius = size.height/2 * 0.6;
    
    CGPoint strPoint = CGPointMake(strRadius + 5, size.height/2 - 2);
    CGPoint endPoint = CGPointMake(size.width-endRadius - 1, strPoint.y);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, NULL, strPoint.x, strPoint.y, strRadius, -M_PI/2, M_PI-M_PI/2, YES);
    CGPathAddLineToPoint(path, NULL, endPoint.x, endPoint.y + endRadius);
    CGPathAddArc(path, NULL, endPoint.x, endPoint.y, endRadius, M_PI/2, M_PI+M_PI/2, YES);
    CGPathAddLineToPoint(path, NULL, strPoint.x, strPoint.y - strRadius);
    
    CGPathCloseSubpath(path);
    
    CGContextAddPath(context, path);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillPath(context);
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    CGPathRelease(path);
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

- (UIColor*)colorForValue:(CGFloat)value
{
    if(value<1/3.0){
        return [UIColor colorWithWhite:value/0.3 alpha:1];
    }
    return [UIColor colorWithHue:((value-1/3.0)/0.7)*2/3.0 saturation:1 brightness:1 alpha:1];
}

#pragma mark -- 初始化菜单栏

- (void)setMenu
{
    CGFloat W = 40;
    
    _colorSlider = [self defaultSliderWithWidth:_menuView.frame.size.width - W - 20];
    
    CGRect frame = _colorSlider.frame ;
    frame.origin.x = 10;
    frame.origin.y  = 5;
    _colorSlider.frame = frame ;
    
    [_colorSlider addTarget:self action:@selector(colorSliderDidChange:) forControlEvents:UIControlEventValueChanged];
    _colorSlider.backgroundColor = [UIColor colorWithPatternImage:[self colorSliderBackground]];
    _colorSlider.value = 0.5;
    [_menuView addSubview:_colorSlider];
    
    _widthSlider = [self defaultSliderWithWidth:_colorSlider.frame.size.width];
    frame.origin.x = 10;
    frame.origin.y  = _colorSlider.frame.origin.y + _colorSlider.frame.size.height + 5;
    _widthSlider.frame = frame ;

    [_widthSlider addTarget:self action:@selector(widthSliderDidChange:) forControlEvents:UIControlEventValueChanged];
    _widthSlider.value = 0.5;
    _widthSlider.backgroundColor = [UIColor colorWithPatternImage:[self widthSliderBackground]];
    [_menuView addSubview:_widthSlider];
    
    _strokePreview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W - 5, W - 5)];
    _strokePreview.layer.cornerRadius = _strokePreview.frame.size.width/2;
    _strokePreview.layer.borderWidth = 1;
    _strokePreview.layer.borderColor = [[UIColor grayColor]colorWithAlphaComponent:0.3].CGColor;
    _strokePreview.center = CGPointMake(_menuView.frame.size.width-W/2, _menuView.frame.size.height/2);
    [_menuView addSubview:_strokePreview];
    
    _strokePreviewBackground = [[UIView alloc] initWithFrame:_strokePreview.frame];
    _strokePreviewBackground.layer.cornerRadius = _strokePreviewBackground.frame.size.height/2;
    _strokePreviewBackground.alpha = 0.3;
    [_strokePreviewBackground addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(strokePreviewDidTap:)]];
    [_menuView insertSubview:_strokePreviewBackground aboveSubview:_strokePreview];
    
    _eraserIcon = [[UIImageView alloc] initWithFrame:_strokePreview.frame];
    _eraserIcon.image  =  [UIImage imageNamed:@"mosaic_eraser"];
    _eraserIcon.hidden = YES;
    [_menuView addSubview:_eraserIcon];
    
    _menuView.clipsToBounds = NO;
    
    [self colorSliderDidChange:_colorSlider];
    [self widthSliderDidChange:_widthSlider];
}

#pragma mark -- 滑块值发生改变

- (void)colorSliderDidChange:(UISlider*)sender
{
    if(_eraserIcon.hidden){
        _strokePreview.backgroundColor = [self colorForValue:_colorSlider.value];
        _strokePreviewBackground.backgroundColor = _strokePreview.backgroundColor;
    }
}

- (void)widthSliderDidChange:(UISlider*)sender
{
    CGFloat scale = MAX(0.05, _widthSlider.value);
    _strokePreview.transform = CGAffineTransformMakeScale(scale, scale);
    _strokePreview.layer.borderWidth = 2/scale;
    
    if(_circleView){
        int w = MIN(MAX_DRAW_WIDTH,MAX(10, _widthSlider.value * MAX_DRAW_WIDTH));
        _circleView.frame = CGRectMake(0, 0, w, w) ;
        _circleView.layer.cornerRadius = _circleView.frame.size.width/2 ;
        _circleView.center = CGPointMake(_magnifierView.center.x-_magnifierView.frame.origin.x,_magnifierView.center.y-_magnifierView.frame.origin.y) ;
    }
}

#pragma mark -- UIGestureRecognizer

- (void)strokePreviewDidTap:(UITapGestureRecognizer*)sender
{
    _eraserIcon.hidden = !_eraserIcon.hidden;
    _strokePreview.hidden = !_eraserIcon.hidden ;
    
    if(_eraserIcon.hidden){
        [self colorSliderDidChange:_colorSlider];
    }else{
        _strokePreview.backgroundColor = [[UIColor grayColor]colorWithAlphaComponent:0.5];
        _strokePreviewBackground.backgroundColor = _strokePreview.backgroundColor;
    }
}

- (void)drawingViewDidPan:(UIPanGestureRecognizer*)sender
{
    CGPoint currentDraggingPosition = [sender locationInView:_drawingView];
    
    if(sender.state == UIGestureRecognizerStateBegan){
        _prevDraggingPosition = currentDraggingPosition;
    }
    
    if(sender.state != UIGestureRecognizerStateEnded){
        [self drawLine:_prevDraggingPosition to:currentDraggingPosition];
        [self showMagnifierView:currentDraggingPosition];
    }else if(sender.state == UIGestureRecognizerStateEnded ||
             sender.state == UIGestureRecognizerStateCancelled ||
             sender.state == UIGestureRecognizerStateFailed){
        _magnifierView.hidden = YES ;
    }
    _prevDraggingPosition = currentDraggingPosition;
}

#pragma mark -- 绘制线条

-(void)drawLine:(CGPoint)from to:(CGPoint)to
{
    CGSize size = _drawingView.frame.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [_drawingView.image drawAtPoint:CGPointZero];
    
    CGFloat strokeWidth = MIN(MAX_DRAW_WIDTH,MAX(1, _widthSlider.value * MAX_DRAW_WIDTH));
    UIColor *strokeColor = _strokePreview.backgroundColor;
    
    CGContextSetLineWidth(context, strokeWidth);
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    CGContextSetLineCap(context, kCGLineCapRound);
    
    if(!_eraserIcon.hidden){
        CGContextSetBlendMode(context, kCGBlendModeClear);
    }
    
    CGContextMoveToPoint(context, from.x, from.y);
    CGContextAddLineToPoint(context, to.x, to.y);
    CGContextStrokePath(context);
    
    _drawingView.image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
}

#pragma mark -- 生成最终的图片

- (void)genDrawImageWithBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *image = [self buildImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image, nil, nil);
        });
    });
}


- (UIImage*)buildImage
{
    UIGraphicsBeginImageContextWithOptions(_originalImage.size, YES, 0.0);
    
    [_originalImage drawAtPoint:CGPointZero];
    [_drawingView.image drawInRect:CGRectMake(0, 0, _originalImage.size.width, _originalImage.size.height)];
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

#pragma mark -- 显示放大镜

- (void)showMagnifierView:(CGPoint)pt
{
    CGRect clipRect = CGRectMake(pt.x, pt.y, 60, 60);
    
    _magnifierView.hidden = NO ;
    
    clipRect.origin.x = pt.x / _drawingView.frame.size.width * _originalImage.size.width - 30;
    clipRect.origin.y = pt.y / _drawingView.frame.size.height * _originalImage.size.height - 30;
    UIImage* image1 = [_originalImage clipImageInRect:clipRect];
    
    clipRect.origin.x = pt.x / _drawingView.frame.size.width * _drawingView.image.size.width - 30;
    clipRect.origin.y = pt.y / _drawingView.frame.size.height * _drawingView.image.size.height - 30;
    UIImage *image2 = [_drawingView.image clipImageInRect:clipRect];
    
    _magnifierImageView.image = [self bulidMagnifierImage:image1 :image2];
    
    if(CGRectContainsPoint(_magnifierView.frame, pt)){
        
        if(pt.x < _drawingView.frame.size.width/2){
            
            [UIView animateWithDuration:0.3 animations:^{
                CGRect frame = _magnifierView.frame ;
                frame.origin.x = _drawingView.frame.size.width - _magnifierView.frame.size.width - 5;
                _magnifierView.frame = frame ;
            }];
            
        }else{
            
            [UIView animateWithDuration:0.3 animations:^{
                CGRect frame = _magnifierView.frame ;
                frame.origin.x = 5 ;
                _magnifierView.frame = frame ;
            }];
            
        }
        
    }
}

- (UIImage*)bulidMagnifierImage:(UIImage*)image1 :(UIImage*)image2
{
    UIGraphicsBeginImageContextWithOptions(_drawingView.frame.size, NO, 1);
    
    [image1 drawInRect:CGRectMake(0, 0, _drawingView.frame.size.width, _drawingView.frame.size.height)];
    [image2 drawInRect:CGRectMake(0, 0, _drawingView.frame.size.width, _drawingView.frame.size.height)];
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

@end
