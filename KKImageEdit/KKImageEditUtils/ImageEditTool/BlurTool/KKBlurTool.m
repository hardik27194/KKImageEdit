//
//  BlurTool.m
//
//  Created by finger on 2015/10/19.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "KKBlurTool.h"
#import "UIView+Extension.h"
#import "UIImage+Extension.h"
#import "KKImageEditToolItem.h"

typedef NS_ENUM(NSUInteger, BlurType)
{
    kBlurTypeNormal = 0,
    kBlurTypeCircle,
    kBlurTypeBand,
};


@interface BlurCircle : UIView
{
    
}
@property (nonatomic, strong) UIColor *color;

@end

#pragma mark- UI components

@implementation BlurCircle

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
    
    CGRect rct = self.bounds;
    rct.origin.x = 0.35*rct.size.width;
    rct.origin.y = 0.35*rct.size.height;
    rct.size.width *= 0.3;
    rct.size.height *= 0.3;
    
    CGContextSetStrokeColorWithColor(context, self.color.CGColor);
    CGContextStrokeEllipseInRect(context, rct);
    
    self.alpha = 1;
    [UIView animateWithDuration:0.3 delay:1 options: UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.alpha = 0;
    }completion:^(BOOL finished) {
    }];
}

@end


////////////////////////////////////////////////////////////////////////////////////////

@interface BlurBand : UIView
{
    
}
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) CGFloat offset;

@end

@implementation BlurBand

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        _scale    = 1;
        _rotation = 0;
        _offset   = 0;
    }
    return self;
}

- (void)setScale:(CGFloat)scale
{
    _scale = scale;
    
    [self calcTransform];
}

- (void)setRotation:(CGFloat)rotation
{
    _rotation = rotation;
    
    [self calcTransform];
}

- (void)setOffset:(CGFloat)offset
{
    _offset = offset;
    
    [self calcTransform];
}

- (void)calcTransform
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, -self.offset*sin(self.rotation), self.offset*cos(self.rotation));
    transform = CGAffineTransformRotate(transform, self.rotation);
    transform = CGAffineTransformScale(transform, 1, self.scale);
    self.transform = transform;
}

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

- (void)setTransform:(CGAffineTransform)transform
{
    [super setTransform:transform];
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rct = self.bounds;
    rct.origin.y = 0.3*rct.size.height;
    rct.size.height *= 0.4;
    
    CGContextSetLineWidth(context, 1/self.scale);
    CGContextSetStrokeColorWithColor(context, self.color.CGColor);
    CGContextStrokeRect(context, rct);
    
    self.alpha = 1;
    [UIView animateWithDuration:0.3 delay:1 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.alpha = 0;
    }completion:^(BOOL finished) {
        
    }];
}

@end

////////////////////////////////////////////////////////////////////////////////////////

@interface KKBlurTool()<UIGestureRecognizerDelegate,KKImageEditToolItemDelegate>
{
    UIImage *_originalImage;//原图
    
    UIImage *_thumbnailImage;//原图的缩略图，用于生成模糊图_blurImage
    UIImage *_blurImage;//覆盖在原图上层的模糊图
    
    UIView *superView ;
    UISlider *_blurSlider;
    UIScrollView *_menuScroll;
    UIImageView *_handlerView;
    
    BlurCircle *_circleView;
    BlurBand *_bandView;
    CGRect _bandImageRect;
    
    KKImageEditToolItem *lastItem;
    BlurType _blurType;
}

@end

@implementation KKBlurTool

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image
{
    superView= view ;
    
    _blurType = kBlurTypeNormal;
    _originalImage = image;
    _thumbnailImage = [_originalImage resize:frame.size];
    
    _handlerView = [[UIImageView alloc] initWithFrame:frame];
    _handlerView.userInteractionEnabled = YES ;
    _handlerView.contentMode = UIViewContentModeScaleAspectFit;
    _handlerView.clipsToBounds = YES ;
    [view addSubview:_handlerView];
    [self setHandlerView];
    
    _menuScroll = [[UIScrollView alloc] initWithFrame:menuView.bounds];
    _menuScroll.backgroundColor = [UIColor blackColor];
    _menuScroll.showsHorizontalScrollIndicator = NO;
    [menuView addSubview:_menuScroll];
    [self setBlurMenu];
    
    _blurSlider = [self sliderWithValue:0.2 minimumValue:0 maximumValue:1];
    _blurSlider.superview.center = CGPointMake(superView.width/2, superView.height-_blurSlider.height - 10);
    
    [self setDefaultParams];
    [self sliderDidChange:nil];
}

- (void)cleanup
{
    [_blurSlider.superview removeFromSuperview];
    [_handlerView removeFromSuperview];
    
    [UIView animateWithDuration:0.3 animations:^{
        _menuScroll.transform = CGAffineTransformMakeTranslation(0, _menuScroll.height);
    }completion:^(BOOL finished) {
        [_menuScroll removeFromSuperview];
    }];
}

#pragma mark -- 生成最终的图片

- (void)genBlurImageWithBlock:(void(^)(UIImage *image))completionBlock
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        UIImage *blurImage = [_originalImage gaussBlur:_blurSlider.value];
        UIImage *image = [self buildResultImage:_originalImage withBlurImage:blurImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image);
        });
        
    });
}

#pragma mark -- 设置菜单栏

- (void)setBlurMenu
{
    NSArray *_menu = @[
                       @{@"title":@"正常", @"name":[NSNumber numberWithInteger:kBlurTypeNormal]},
                       @{@"title":@"Cirlcle",@"name":[NSNumber numberWithInteger:kBlurTypeCircle]},
                       @{@"title":@"Band", @"name":[NSNumber numberWithInteger:kBlurTypeBand]},
                       ];
    
    CGFloat W = 70;
    CGFloat H = _menuScroll.height;
    CGFloat panding = (_menuScroll.width - _menu.count * W) / (_menu.count + 1 ) ;
    CGFloat x = panding;
    
    for(NSDictionary *obj in _menu){
        
        KKImageEditToolItem *item = [[KKImageEditToolItem alloc]init];
        item.itemTitle = [obj objectForKey:@"title"];
        item.delegate = self ;
        item.editType = KKImageEditTypeRotate ;
        item.editInfo = obj ;
        item.selected = NO ;
        item.frame = CGRectMake(x, 0, W, H);
        
        BlurType type = [[obj objectForKey:@"name"]integerValue];
        if(type == kBlurTypeNormal){
            item.itemImage = [UIImage imageNamed:@"btn_normal"];
        }else if(type == kBlurTypeBand){
            item.itemImage = [UIImage imageNamed:@"btn_band"];
        }else if(type == kBlurTypeCircle){
            item.itemImage = [UIImage imageNamed:@"btn_circle"];
        }
        
        if(type == kBlurTypeNormal){
            item.selected = YES ;
            lastItem = item ;
        }
        
        [_menuScroll addSubview:item];
        
        x += (W + panding);
        
    }
    _menuScroll.contentSize = CGSizeMake(MAX(x, _menuScroll.frame.size.width+1), 0);
    
    _menuScroll.transform = CGAffineTransformMakeTranslation(0, _menuScroll.height);
    [UIView animateWithDuration:0.3 animations:^{
        _menuScroll.transform = CGAffineTransformIdentity;
    }];
    
}

#pragma mark -- 设置操作区域

- (void)setHandlerView
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandlerView:)];
    tapGesture.numberOfTapsRequired = 1 ;
    tapGesture.numberOfTouchesRequired = 1 ;
    tapGesture.delegate = self;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandlerView:)];
    panGesture.maximumNumberOfTouches = 1;
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchHandlerView:)];
    pinch.delegate = self;
    
    UIRotationGestureRecognizer *rot   = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateHandlerView:)];
    rot.delegate = self;
    
    [_handlerView addGestureRecognizer:tapGesture];
    [_handlerView addGestureRecognizer:panGesture];
    [_handlerView addGestureRecognizer:pinch];
    [_handlerView addGestureRecognizer:rot];
}

#pragma mark -- 初始化模糊参数

- (void)setDefaultParams
{
    CGFloat W = 1.5 * MIN(_handlerView.width, _handlerView.height);
    
    _circleView = [[BlurCircle alloc] initWithFrame:CGRectMake(_handlerView.width/2-W/2, _handlerView.height/2-W/2, W, W)];
    _circleView.backgroundColor = [UIColor clearColor];
    _circleView.color = [UIColor whiteColor];
    
    CGFloat H = _handlerView.height;
    CGFloat R = sqrt((_handlerView.width*_handlerView.width) + (_handlerView.height*_handlerView.height));
    _bandView = [[BlurBand alloc] initWithFrame:CGRectMake(0, 0, R, H)];
    _bandView.center = CGPointMake(_handlerView.width/2, _handlerView.height/2);
    _bandView.backgroundColor = [UIColor clearColor];
    _bandView.color = [UIColor whiteColor];
    
    CGFloat ratio = _originalImage.size.width / _handlerView.width;
    _bandImageRect = _bandView.frame;
    _bandImageRect.size.width  *= ratio;
    _bandImageRect.size.height *= ratio;
    _bandImageRect.origin.x *= ratio;
    _bandImageRect.origin.y *= ratio;
    
}

#pragma mark -- UISlider

- (UISlider *)sliderWithValue:(CGFloat)value minimumValue:(CGFloat)min maximumValue:(CGFloat)max
{
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 280, 30)];
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, slider.height)];
    container.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.3];
    container.layer.cornerRadius = slider.height/2;
    
    slider.continuous = NO;
    [slider addTarget:self action:@selector(sliderDidChange:) forControlEvents:UIControlEventValueChanged];
    
    [slider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    
    slider.maximumValue = max;
    slider.minimumValue = min;
    slider.value = value;
    
    [container addSubview:slider];
    [superView addSubview:container];
    
    return slider;
}

- (void)sliderDidChange:(UISlider*)slider
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        _blurImage = [_thumbnailImage gaussBlur:_blurSlider.value];
        [self buildTempBulrImage:_thumbnailImage blurImage:_blurImage];
    });
}

#pragma mark -- KKImageEditToolItemDelegate

- (void)imageEditItem:(KKImageEditToolItem *)item clickItemWithType:(KKImageEditType)editType editInfo:(NSDictionary *)editInfo
{
    BlurType type = [[editInfo objectForKey:@"name"]integerValue];
    
    if(type != _blurType){
        
        lastItem.selected = NO ;
        lastItem = item ;
        lastItem.selected = YES ;
        
        _blurType = type;
        
        [_circleView removeFromSuperview];
        [_bandView removeFromSuperview];
        
        switch (_blurType)
        {
            case kBlurTypeNormal:
                break;
            case kBlurTypeCircle:
                [_handlerView addSubview:_circleView];
                [_circleView setNeedsDisplay];
                break;
            case kBlurTypeBand:
                [_handlerView addSubview:_bandView];
                [_bandView setNeedsDisplay];
                break;
            default:
                break;
        }
        [self buildTempBulrImage:_thumbnailImage blurImage:_blurImage];
    }
}

#pragma mark -- 生成临时覆盖在原图上的模糊图

- (void)buildTempBulrImage:(UIImage*)originalImage blurImage:(UIImage *)blurImage
{
    static BOOL inProgress = NO;
    
    if(inProgress){ return; }
    
    inProgress = YES;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *image = [self buildResultImage:originalImage withBlurImage:blurImage];
        [_handlerView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
        inProgress = NO;
    });
}

#pragma mark -- 根据模糊类型生成对应的模糊图

- (UIImage*)buildResultImage:(UIImage*)originalImage withBlurImage:(UIImage*)blurImage
{
    UIImage *result = blurImage;
    
    switch (_blurType)
    {
        case kBlurTypeCircle:
            result = [self circleBlurImage:originalImage withBlurImage:blurImage];
            break;
        case kBlurTypeBand:
            result = [self bandBlurImage:originalImage withBlurImage:blurImage];
            break;
        default:
            break;
    }
    return result;
}

#pragma mark -- 圆形模糊图

- (UIImage*)circleBlurImage:(UIImage*)originalImage withBlurImage:(UIImage*)blurImage
{
    CGFloat ratio = originalImage.size.width / _handlerView.width;
    CGRect frame  = _circleView.frame;
    frame.size.width  *= ratio;
    frame.size.height *= ratio;
    frame.origin.x *= ratio;
    frame.origin.y *= ratio;
    
    UIImage *mask = [UIImage imageNamed:@"circleMask"];
    UIGraphicsBeginImageContext(originalImage.size);
    {
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext() , [[UIColor whiteColor] CGColor]);
        CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, originalImage.size.width, originalImage.size.height));
        [mask drawInRect:frame];
        mask = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return [self blurImage:originalImage withBlurImage:blurImage andMask:mask];
}

#pragma mark -- 矩形模糊图

- (UIImage*)bandBlurImage:(UIImage*)originalImage withBlurImage:(UIImage*)blurImage
{
    UIImage *mask = [UIImage imageNamed:@"bandMask"];
    
    UIGraphicsBeginImageContext(originalImage.size);
    {
        CGContextRef context =  UIGraphicsGetCurrentContext();
        
        CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
        CGContextFillRect(context, CGRectMake(0, 0,originalImage.size.width, originalImage.size.height));
        
        CGContextSaveGState(context);
        CGFloat ratio = originalImage.size.width / _originalImage.size.width;
        CGFloat Tx = (_bandImageRect.size.width/2  + _bandImageRect.origin.x)*ratio;
        CGFloat Ty = (_bandImageRect.size.height/2 + _bandImageRect.origin.y)*ratio;
        
        CGContextTranslateCTM(context, Tx, Ty);
        CGContextRotateCTM(context, _bandView.rotation);
        CGContextTranslateCTM(context, 0, _bandView.offset*originalImage.size.width/_handlerView.width);
        CGContextScaleCTM(context, 1, _bandView.scale);
        CGContextTranslateCTM(context, -Tx, -Ty);
        
        CGRect rct = _bandImageRect;
        rct.size.width  *= ratio;
        rct.size.height *= ratio;
        rct.origin.x    *= ratio;
        rct.origin.y    *= ratio;
        
        [mask drawInRect:rct];
        
        CGContextRestoreGState(context);
        
        mask = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return [self blurImage:originalImage withBlurImage:blurImage andMask:mask];
}

- (UIImage*)blurImage:(UIImage*)originalImage withBlurImage:(UIImage*)blurImage andMask:(UIImage*)maskImage
{
    UIImage *tmp = [originalImage maskedImage:maskImage];//从底图中取出遮罩层所在区域的图片
    
    UIGraphicsBeginImageContext(blurImage.size);
    {
        //先绘制模化图，再绘制遮罩图
        [blurImage drawAtPoint:CGPointZero];
        [tmp drawInRect:CGRectMake(0, 0, blurImage.size.width, blurImage.size.height)];
        tmp = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return tmp;
}

#pragma mark -- Gesture handler

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)tapHandlerView:(UITapGestureRecognizer*)sender
{
    switch (_blurType)
    {
        case kBlurTypeCircle:
        {
            CGPoint point = [sender locationInView:_handlerView];
            
            _circleView.center = point;
            
            [self buildTempBulrImage:_thumbnailImage blurImage:_blurImage];
            
            break;
        }
        case kBlurTypeBand:
        {
            CGPoint point = [sender locationInView:_handlerView];
            point = CGPointMake(point.x-_handlerView.width/2, point.y-_handlerView.height/2);
            point = CGPointMake(point.x*cos(-_bandView.rotation)-point.y*sin(-_bandView.rotation), point.x*sin(-_bandView.rotation)+point.y*cos(-_bandView.rotation));
            _bandView.offset = point.y;
            
            [self buildTempBulrImage:_thumbnailImage blurImage:_blurImage];
            
            break;
        }
            
        default:break;
    }
}

- (void)panHandlerView:(UIPanGestureRecognizer*)sender
{
    switch (_blurType)
    {
        case kBlurTypeCircle:
        {
            CGPoint point = [sender locationInView:_handlerView];
            
            _circleView.center = point;
            
            [self buildTempBulrImage:_thumbnailImage blurImage:_blurImage];
            
            break;
        }
        case kBlurTypeBand:
        {
            CGPoint point = [sender locationInView:_handlerView];
            point = CGPointMake(point.x-_handlerView.width/2, point.y-_handlerView.height/2);
            point = CGPointMake(point.x*cos(-_bandView.rotation)-point.y*sin(-_bandView.rotation), point.x*sin(-_bandView.rotation)+point.y*cos(-_bandView.rotation));
            
            _bandView.offset = point.y;
            
            [self buildTempBulrImage:_thumbnailImage blurImage:_blurImage];
            
            break;
        }
        default:
            break;
    }
}

- (void)pinchHandlerView:(UIPinchGestureRecognizer*)sender
{
    switch (_blurType)
    {
        case kBlurTypeCircle:
        {
            static CGRect initialFrame;
            if (sender.state == UIGestureRecognizerStateBegan) {
                initialFrame = _circleView.frame;
            }
            
            CGFloat scale = sender.scale;
            CGRect rct;
            rct.size.width  = MAX(MIN(initialFrame.size.width*scale, 3*MAX(_handlerView.width, _handlerView.height)), 0.3*MIN(_handlerView.width, _handlerView.height));
            rct.size.height = rct.size.width;
            rct.origin.x = initialFrame.origin.x + (initialFrame.size.width-rct.size.width)/2;
            rct.origin.y = initialFrame.origin.y + (initialFrame.size.height-rct.size.height)/2;
            
            _circleView.frame = rct;
            
            [self buildTempBulrImage:_thumbnailImage blurImage:_blurImage];
            
            break;
        }
        case kBlurTypeBand:
        {
            static CGFloat initialScale;
            
            if (sender.state == UIGestureRecognizerStateBegan) {
                initialScale = _bandView.scale;
            }
            
            _bandView.scale = MIN(2, MAX(0.2, initialScale * sender.scale));
            
            [self buildTempBulrImage:_thumbnailImage blurImage:_blurImage];
            
            break;
        }
        default:
            break;
    }
}

- (void)rotateHandlerView:(UIRotationGestureRecognizer*)sender
{
    switch (_blurType)
    {
        case kBlurTypeBand:
        {
            static CGFloat initialRotation;
            
            if (sender.state == UIGestureRecognizerStateBegan) {
                initialRotation = _bandView.rotation;
            }
            
            _bandView.rotation = MIN(M_PI/2, MAX(-M_PI/2, initialRotation + sender.rotation));
            
            [self buildTempBulrImage:_thumbnailImage blurImage:_blurImage];
            
            break;
        }
        default:
            break;
    }
    
}

@end
