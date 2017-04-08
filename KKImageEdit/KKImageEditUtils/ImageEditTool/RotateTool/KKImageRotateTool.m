//
//  KKImageRotateTool.m
//
//  Created by finger on 17/2/14.
//  Copyright © 2017年 fingerfinger. All rights reserved.
//

#import "KKImageRotateTool.h"
#import "UIView+Extension.h"
#import "KKImageEditToolItem.h"
#import "UIView+Extension.h"

@interface KKImageRotateTool()<KKImageEditToolItemDelegate>
{
    CGRect _initialRect;
    
    NSInteger _flipState1;
    NSInteger _flipState2;
    
    UIScrollView *menuScrollView ;
    
    UIView *_contentView ;
    UISlider *_rotateSlider;
    UIImageView *_rotateImageView;
}

@end

@implementation KKImageRotateTool

- (id)init
{
    self = [super init];
    
    if(self){
        
        self.rotateTypeArray = @[
                                 @{@"name":[NSNumber numberWithInteger:KKRoteTypeRoundRotate],@"title":@"旋转"},
                                 @{@"name":[NSNumber numberWithInteger:KKRoteTypeFlipHorizonta],@"title":@"水平翻转"},
                                 @{@"name":[NSNumber numberWithInteger:KKRoteTypeFlipVertical],@"title":@"垂直翻转"},
                                 ];
        
    }
    
    return self ;
}

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image
{
    _initialRect = frame;
    
    _flipState1 = 0;
    _flipState2 = 0;
    
    _contentView = [[UIView alloc]initWithFrame:view.bounds];
    [_contentView setBackgroundColor:[UIColor blackColor]];
    [view addSubview:_contentView];
    
    _rotateImageView = [[UIImageView alloc] initWithFrame:frame];
    _rotateImageView.image = image;
    _rotateImageView.contentMode = UIViewContentModeScaleAspectFit ;
    [_contentView addSubview:_rotateImageView];
    
    _rotateSlider = [self sliderWithValue:0 minimumValue:-1 maximumValue:1];
    _rotateSlider.superview.center = CGPointMake(_contentView.frame.size.width/2, _contentView.frame.size.height-30);
    
    menuScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, menuView.height, menuView.width, menuView.height)];
    menuScrollView.backgroundColor = [UIColor blackColor];
    [menuView addSubview:menuScrollView];
    
    CGFloat W = 70;
    CGFloat H = menuScrollView.height;
    CGFloat panding = (menuScrollView.width - self.rotateTypeArray.count * W) / (self.rotateTypeArray.count + 1 ) ;
    CGFloat x = panding;
    
    for(NSDictionary *rotateInfo in self.rotateTypeArray){
        
        KKImageEditToolItem *item = [[KKImageEditToolItem alloc]init];
        item.itemTitle = [rotateInfo objectForKey:@"title"];
        item.delegate = self ;
        item.editType = KKImageEditTypeRotate ;
        item.editInfo = rotateInfo ;
        item.frame = CGRectMake(x, 0, W, H);
        
        KKRoteImageType type = [[rotateInfo objectForKey:@"name"]integerValue];
        if(type == KKRoteTypeRoundRotate){
            item.itemImage = [UIImage imageNamed:@"rotate_round"];
        }else if(type == KKRoteTypeFlipHorizonta){
            item.itemImage = [UIImage imageNamed:@"flip_hori"];
        }else if(type == KKRoteTypeFlipVertical){
            item.itemImage = [UIImage imageNamed:@"flip_veri"];
        }
        
        [menuScrollView addSubview:item];
        
        x += (W + panding);
    }
    
    menuScrollView.contentSize = CGSizeMake(MAX(x, menuScrollView.frame.size.width+1), 0);
    
    [UIView animateWithDuration:0.3 animations:^{
        [menuScrollView setFrame:menuView.bounds];
    }];
}

- (void)cleanup
{
    [menuScrollView removeFromSuperview];
    [_contentView removeFromSuperview];
}

#pragma mark -- 拖动滑块改变图片旋转角度

- (UISlider*)sliderWithValue:(CGFloat)value minimumValue:(CGFloat)min maximumValue:(CGFloat)max
{
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10, 0, 260, 30)];
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, slider.frame.size.height)];
    container.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    container.layer.cornerRadius = slider.frame.size.height/2;
    
    slider.continuous = YES;
    [slider addTarget:self action:@selector(sliderDidChange:) forControlEvents:UIControlEventValueChanged];
    
    [slider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    
    slider.maximumValue = max;
    slider.minimumValue = min;
    slider.value = value;
    
    [container addSubview:slider];
    [_contentView addSubview:container];
    
    return slider;
}

- (void)sliderDidChange:(UISlider*)slider
{
    [self rotateStateDidChange];
}

- (void)rotateStateDidChange
{
    CATransform3D transform = [self rotateTransform:CATransform3DIdentity clockwise:YES];
    
    CGFloat arg = _rotateSlider.value*M_PI;
    CGFloat Wnew = fabs(_initialRect.size.width * cos(arg)) + fabs(_initialRect.size.height * sin(arg));
    CGFloat Hnew = fabs(_initialRect.size.width * sin(arg)) + fabs(_initialRect.size.height * cos(arg));
    
    CGFloat Rw = _initialRect.size.width / Wnew;
    CGFloat Rh = _initialRect.size.height / Hnew;
    CGFloat scale = MIN(Rw, Rh);
    
    transform = CATransform3DScale(transform, scale, scale, 1);
    
    _rotateImageView.layer.transform = transform;
}

#pragma mark -- 计算旋转角度

- (CATransform3D)rotateTransform:(CATransform3D)initialTransform clockwise:(BOOL)clockwise
{
    CGFloat arg = _rotateSlider.value*M_PI;
    if(!clockwise){
        arg *= -1;
    }
    
    CATransform3D transform = initialTransform;
    transform = CATransform3DRotate(transform, arg, 0, 0, 1);
    transform = CATransform3DRotate(transform, _flipState1*M_PI, 0, 1, 0);
    transform = CATransform3DRotate(transform, _flipState2*M_PI, 1, 0, 0);
    
    return transform;
}

#pragma mark -- 水平、垂直、圆滑翻转

- (void)rotateImageWithType:(KKRoteImageType)type
{
    switch (type)
    {
        case KKRoteTypeRoundRotate:
        {
            CGFloat value = (int)floorf((_rotateSlider.value + 1)*2) + 1;
            
            if(value>4){
                value -= 4;
            }
            _rotateSlider.value = value / 2 - 1;
            
            break;
        }
        case KKRoteTypeFlipHorizonta:
        {
            _flipState1 = (_flipState1==0) ? 1 : 0;
            
            break;
        }
        case KKRoteTypeFlipVertical:
        {
            _flipState2 = (_flipState2==0) ? 1 : 0;
            
            break;
        }
        default:break;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        [self rotateStateDidChange];
    }completion:^(BOOL finished) {
    }];
}

#pragma mark -- KKImageEditToolItemDelegate

- (void)imageEditItem:(KKImageEditToolItem *)item clickItemWithType:(KKImageEditType)editType editInfo:(NSDictionary *)editInfo
{
    if(item.selected){
        return ;
    }
    
    item.selected = NO ;
    
    KKRoteImageType type = [[editInfo objectForKey:@"name"]integerValue];
    
    [self rotateImageWithType:type];
}

#pragma mark -- 生成最终的图片

- (UIImage*)buildImage:(UIImage*)image
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey, ciImage, nil];
    [filter setDefaults];
    
    CGAffineTransform transform = CATransform3DGetAffineTransform([self rotateTransform:CATransform3DIdentity clockwise:NO]);
    [filter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

@end
