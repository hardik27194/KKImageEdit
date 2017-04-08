//
//  DrawTool.m
//
//  Created by finger on 2014/06/20.
//  Copyright (c) 2014年 finger. All rights reserved.
//

#import "KKImageMosaicTool.h"
#import "UIImage+Extension.h"

#define MAX_STROKE_WIDTH 40
#define SLIDER_HEIGHT 34

@implementation KKImageMosaicTool
{
    UIView *_menuView ;
    UIView *_strokePreview;
    UIView *_strokePreviewBackground;
    UISlider *_strokeSlider;
    UIImageView *_eraserIcon;
    
    UIView *_contentView ;
    
    UIImage *_oriImage ;//原图
    UIImage *_mosaicImage ;//马赛克底图
    UIImage *_maskImage;//原图与马赛克底图之间的遮罩图
    UIImageView *_imageView ;
    
    CGPoint _prevDraggingPosition;
    
    //放大镜
    UIView *_magnifierView ;
    UIImageView *_magnifierImageView;
    UIView *_circleView;
}

#pragma mark- implementation

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image
{
    _oriImage = image ;
    
    UIImage *tempImage = [_oriImage scaleWithFactor:0.1 quality:0.1];
    _mosaicImage = [self createMosaicImage:tempImage];
    
    _contentView = [[UIView alloc]initWithFrame:view.bounds];
    [view addSubview:_contentView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drawingViewDidPan:)];
    panGesture.maximumNumberOfTouches = 1;
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressGesture:)];
    longPressGesture.minimumPressDuration = 2 ;
    
    _imageView = [[UIImageView alloc]initWithFrame:frame];
    _imageView.contentMode = UIViewContentModeScaleAspectFit ;
    _imageView.userInteractionEnabled = YES;
    _imageView.image = image;
    [_imageView addGestureRecognizer:panGesture];
    [_imageView addGestureRecognizer:longPressGesture];
    [_contentView addSubview:_imageView];
    
    _magnifierView = [[UIView alloc]initWithFrame:CGRectMake(5, 5, MAX_STROKE_WIDTH+5, MAX_STROKE_WIDTH+5)];
    _magnifierView.layer.cornerRadius = 5 ;
    _magnifierView.layer.borderColor = [[UIColor whiteColor]CGColor];
    _magnifierView.layer.borderWidth = 1 ;
    _magnifierView.clipsToBounds = YES ;
    _magnifierView.hidden = YES ;
    [_imageView addSubview:_magnifierView];
    
    _magnifierImageView = [[UIImageView alloc]initWithFrame:_magnifierView.bounds];
    [_magnifierView addSubview:_magnifierImageView];
    
    int w = MIN(MAX_STROKE_WIDTH,MAX(10, _strokeSlider.value * MAX_STROKE_WIDTH));
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
    
    [self setMenu];
    
    [self sliderDidChange:_strokeSlider];
    
    _menuView.transform = CGAffineTransformMakeTranslation(0, _menuView.frame.size.height);
    [UIView animateWithDuration:0.3 animations:^{
        _menuView.transform = CGAffineTransformIdentity;
    }];
}

- (void)cleanup
{
    [_circleView removeFromSuperview];
    [_magnifierImageView removeFromSuperview];
    [_magnifierView removeFromSuperview];
    
    [_imageView removeFromSuperview];
    [_contentView removeFromSuperview];

    [UIView animateWithDuration:0.3 animations:^{
        _menuView.transform = CGAffineTransformMakeTranslation(0, _menuView.frame.size.height);
    }completion:^(BOOL finished) {
        [_menuView removeFromSuperview];
    }];
}

#pragma mark -- Create Default Slider

- (UISlider*)defaultSliderWithX:(CGFloat)x Y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height
{
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(x, y, width, height)];
    
    [slider setMinimumTrackTintColor:[UIColor redColor]];
    [slider setMaximumTrackTintColor:[UIColor whiteColor]];
    [slider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    
    return slider;
}

#pragma mark -- 初始化菜单栏

- (void)setMenu
{
    int W = 40 ;
    
    _strokePreview = [[UIView alloc] initWithFrame:CGRectMake(0, _menuView.frame.size.height/2 - W/2, W, W)];
    _strokePreview.layer.cornerRadius = _strokePreview.frame.size.height/2;
    _strokePreview.layer.borderWidth = 1;
    _strokePreview.layer.borderColor = [[UIColor grayColor]colorWithAlphaComponent:0.3].CGColor;
    _strokePreview.backgroundColor = [UIColor redColor];
    [_menuView addSubview:_strokePreview];
    
    _strokePreviewBackground = [[UIView alloc] initWithFrame:_strokePreview.frame];
    _strokePreviewBackground.layer.cornerRadius = _strokePreviewBackground.frame.size.height/2;
    _strokePreviewBackground.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.5];
    [_strokePreviewBackground addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(strokePreviewDidTap:)]];
    [_menuView insertSubview:_strokePreviewBackground aboveSubview:_strokePreview];
    
    _eraserIcon = [[UIImageView alloc] initWithFrame:_strokePreview.frame];
    _eraserIcon.image  =  [UIImage imageNamed:@"mosaic_eraser"];
    _eraserIcon.hidden = YES;
    [_menuView addSubview:_eraserIcon];
    
    NSInteger x = _strokePreviewBackground.frame.size.width + _strokePreviewBackground.frame.origin.x ;
    NSInteger y = _strokePreviewBackground.center.y - SLIDER_HEIGHT/2 ;
    _strokeSlider = [self defaultSliderWithX:x Y:y width:_menuView.frame.size.width - x height:SLIDER_HEIGHT] ;
    [_strokeSlider addTarget:self action:@selector(sliderDidChange:) forControlEvents:UIControlEventValueChanged];
    _strokeSlider.value = 0.5;
    [_menuView addSubview:_strokeSlider];
}

#pragma mark -- UIGestureRecognizer

- (void)strokePreviewDidTap:(UITapGestureRecognizer*)sender
{
    _eraserIcon.hidden = !_eraserIcon.hidden;
    _strokePreview.hidden = !_eraserIcon.hidden ;
}

- (void)sliderDidChange:(UISlider*)sender
{
    CGFloat scale = MAX(0.05, _strokeSlider.value);
    _strokePreview.transform = CGAffineTransformMakeScale(scale, scale);
    _strokePreview.layer.borderWidth = 2/scale;
    
    if(_circleView){
        int w = MIN(MAX_STROKE_WIDTH,MAX(10, _strokeSlider.value * MAX_STROKE_WIDTH));
        _circleView.frame = CGRectMake(0, 0, w, w) ;
        _circleView.layer.cornerRadius = _circleView.frame.size.width/2 ;
        _circleView.center = CGPointMake(_magnifierView.center.x-_magnifierView.frame.origin.x,_magnifierView.center.y-_magnifierView.frame.origin.y) ;
    }
}

- (void)longPressGesture:(UIGestureRecognizer*)recognizer
{
    CGPoint pt = [recognizer locationInView:_imageView];
    
    CGRect modefiyRt = CGRectMake(pt.x, pt.y, 60, 60);
    CGRect clipRect = modefiyRt;
    
    _magnifierView.hidden = NO ;
    if(recognizer.state == UIGestureRecognizerStateEnded){
        _magnifierView.hidden = YES ;
        return ;
    }
    
    clipRect.origin.x = pt.x / _imageView.frame.size.width * _imageView.image.size.width - 20 ;
    clipRect.origin.y = pt.y / _imageView.frame.size.height * _imageView.image.size.height - 30 ;
    _magnifierImageView.image = [_imageView.image clipImageInRect:clipRect];
    
    if(CGRectContainsPoint(_magnifierView.frame, pt)){
        
        if(pt.x < _imageView.frame.size.width/2){
            
            [UIView animateWithDuration:0.3 animations:^{
                CGRect frame = _magnifierView.frame ;
                frame.origin.x = _imageView.frame.size.width - _magnifierView.frame.size.width - 5;
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

#pragma mark -- 绘制路径

- (void)drawingViewDidPan:(UIPanGestureRecognizer*)sender
{
    CGPoint currentDraggingPosition = [sender locationInView:_imageView];
    
    if(sender.state == UIGestureRecognizerStateBegan){
        _prevDraggingPosition = currentDraggingPosition;
    }
    
    if(sender.state != UIGestureRecognizerStateEnded){
        
        [self drawLine:_prevDraggingPosition to:currentDraggingPosition];
        
        if(!_eraserIcon.hidden){//擦除
            _imageView.image = [_mosaicImage maskedImage:_maskImage];
            [self showMagnifierView:currentDraggingPosition];
        }else{
            [self showMagnifierView:currentDraggingPosition];
            _imageView.image = [_mosaicImage maskedImage:_maskImage];
        }
        
    }else if(sender.state == UIGestureRecognizerStateEnded ||
             sender.state == UIGestureRecognizerStateCancelled ||
             sender.state == UIGestureRecognizerStateFailed){
        _magnifierView.hidden = YES ;
    }
    
    _prevDraggingPosition = currentDraggingPosition;
}

-(void)drawLine:(CGPoint)from to:(CGPoint)to
{
    CGSize size = _imageView.frame.size;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat strokeWidth = MIN(MAX_STROKE_WIDTH,MAX(1, _strokeSlider.value * MAX_STROKE_WIDTH));
    
    if(_maskImage==nil){
        CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    }else{
        [_maskImage drawAtPoint:CGPointZero];
    }
    
    CGContextSetLineWidth(context, strokeWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    
    if(!_eraserIcon.hidden){//删除，黑色显示原图，白色使原图透明
        CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor]);
    }else{
        CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
    }
    
    CGContextMoveToPoint(context, from.x, from.y);
    CGContextAddLineToPoint(context, to.x, to.y);
    CGContextStrokePath(context);
    
    _maskImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
}

#pragma mark -- 显示放大镜

- (void)showMagnifierView:(CGPoint)pt
{
    CGRect modefiyRt = CGRectMake(pt.x, pt.y, 60, 60);
    CGRect clipRect = modefiyRt;
    
    _magnifierView.hidden = NO ;
    
    clipRect.origin.x = pt.x / _imageView.frame.size.width * _oriImage.size.width - 30 ;
    clipRect.origin.y = pt.y / _imageView.frame.size.height * _oriImage.size.height - 30 ;
    UIImage* image1 = [_oriImage clipImageInRect:clipRect];
    
    clipRect.origin.x = pt.x / _imageView.frame.size.width * _imageView.image.size.width - 30 ;
    clipRect.origin.y = pt.y / _imageView.frame.size.height * _imageView.image.size.height - 30 ;
    UIImage* image2 = [_imageView.image clipImageInRect:clipRect];
    
    _magnifierImageView.image = [self bulidMagnifierImage:image1 :image2];
    
    if(CGRectContainsPoint(_magnifierView.frame, pt)){
        
        if(pt.x < _imageView.frame.size.width/2){
            
            [UIView animateWithDuration:0.3 animations:^{
                CGRect frame = _magnifierView.frame ;
                frame.origin.x = _imageView.frame.size.width - _magnifierView.frame.size.width - 5;
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
    UIGraphicsBeginImageContextWithOptions(_imageView.frame.size, NO, 1);
    
    [image1 drawInRect:CGRectMake(0, 0, _imageView.frame.size.width, _imageView.frame.size.height)];
    [image2 drawInRect:CGRectMake(0, 0, _imageView.frame.size.width, _imageView.frame.size.height)];
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

#pragma mark -- 生成最终结果图

- (void)genMosaicImageWithBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *image = [self buildMosaicImage:_oriImage mosaicImage:_mosaicImage maskImage:_maskImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image, nil, nil);
        });
    });
}

#pragma mark -- 融合原图与马赛克掩码图

- (UIImage*)buildMosaicImage:(UIImage*)oriImage mosaicImage:(UIImage*)mosaicImage maskImage:(UIImage*)maskImage
{
    UIGraphicsBeginImageContextWithOptions(oriImage.size, YES, oriImage.scale);
    
    [oriImage drawAtPoint:CGPointZero];
    
    [[mosaicImage maskedImage:maskImage] drawInRect:CGRectMake(0, 0, oriImage.size.width, oriImage.size.height)];
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

#pragma mark -- 生成马赛克底图

- (UIImage*)createMosaicImage:(UIImage*)sourceImage
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:sourceImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIPixellate" keysAndValues:kCIInputImageKey, ciImage, nil];
    [filter setDefaults];
    
    CGFloat R = MIN(sourceImage.size.width, sourceImage.size.height) * 0.045;
    CIVector *vct = [[CIVector alloc] initWithX:sourceImage.size.width/2 Y:sourceImage.size.height/2];
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
