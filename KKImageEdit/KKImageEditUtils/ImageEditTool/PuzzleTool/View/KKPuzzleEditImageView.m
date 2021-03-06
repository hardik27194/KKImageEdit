//
//  puzzleEditImageView.m
//
//  Created by finger on 1/22/16.
//  Copyright (c) 2016年 finger. All rights reserved.
//


#import "KKPuzzleEditImageView.h"

#define ScreenWidth CGRectGetWidth([UIScreen mainScreen].applicationFrame)
#define ScreenHeight CGRectGetHeight([UIScreen mainScreen].applicationFrame)

@interface KKPuzzleEditImageView (Utility)

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center;

@end

@interface KKPuzzleEditImageView()
{
    UIScrollView *_contentView;
    UIImageView *_imageview;
}

@end

@implementation KKPuzzleEditImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initImageView];
    }
    return self;
}

- (void)initImageView
{
    _contentView = [[UIScrollView alloc] initWithFrame:CGRectInset(self.bounds, 0, 0)];
    _contentView.delegate = self;
    _contentView.showsHorizontalScrollIndicator = NO;
    _contentView.showsVerticalScrollIndicator = NO;
    [self addSubview:_contentView];

    _imageview = [[UIImageView alloc] initWithFrame:self.bounds];
    _imageview.frame = CGRectMake(0, 0, ScreenWidth * 2.5, ScreenWidth * 2.5);
    _imageview.userInteractionEnabled = YES;
    [_contentView addSubview:_imageview];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    [doubleTapGesture setNumberOfTapsRequired:2];
    [_imageview addGestureRecognizer:doubleTapGesture];
    
    float minimumScale = self.frame.size.width / _imageview.frame.size.width;
    [_contentView setMinimumZoomScale:minimumScale];
    [_contentView setZoomScale:minimumScale];
    
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
}

- (void)setImageViewData:(UIImage *)imageData
{
    _imageview.image= imageData;
    if (imageData == nil) {
        return;
    }
    
    CGRect rect = CGRectZero;
    CGFloat scale = 1.0f;
    CGFloat w = 0.0f;
    CGFloat h = 0.0f;
    
    if(_contentView.frame.size.width > _contentView.frame.size.height){
        
        w = _contentView.frame.size.width;
        h = w*imageData.size.height/imageData.size.width;
        if(h < _contentView.frame.size.height){
            h = _contentView.frame.size.height;
            w = h*imageData.size.width/imageData.size.height;
        }
        
    }else{
        
        h = _contentView.frame.size.height;
        w = h*imageData.size.width/imageData.size.height;
        if(w < _contentView.frame.size.width){
            w = _contentView.frame.size.width;
            h = w*imageData.size.height/imageData.size.width;
        }
        
    }
    rect.size = CGSizeMake(w, h);
    
    CGFloat scale_w = w / imageData.size.width;
    CGFloat scale_h = h / imageData.size.height;
    if (w > self.frame.size.width || h > self.frame.size.height) {
        scale_w = w / self.frame.size.width;
        scale_h = h / self.frame.size.height;
        if (scale_w > scale_h) {
            scale = 1/scale_w;
        }else{
            scale = 1/scale_h;
        }
    }
    
    if (w <= self.frame.size.width || h <= self.frame.size.height) {
        scale_w = w / self.frame.size.width;
        scale_h = h / self.frame.size.height;
        if (scale_w > scale_h) {
            scale = scale_h;
        }else{
            scale = scale_w;
        }
    }
    
    @synchronized(self){
        
        _imageview.frame = rect;
        //若要使self.layer显示maskLayer的形状，需要使maskLayer的填充颜色为不透明(可以是任意颜色)
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = [self.realCellArea CGPath];
        maskLayer.fillColor = [[UIColor redColor] CGColor];
        maskLayer.frame = _imageview.frame;
        maskLayer.strokeColor = [UIColor clearColor].CGColor;
        self.layer.mask = maskLayer;
        
        [_contentView setZoomScale:0.2 animated:YES];
        
        [self setNeedsLayout];
    }
}


- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL contained=[_realCellArea containsPoint:point];
    
    return contained;
}

#pragma mark - Zoom methods

- (void)handleDoubleTap:(UIGestureRecognizer *)gesture
{
    float newScale = _contentView.zoomScale * 1.2;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gesture locationInView:_imageview]];
    [_contentView zoomToRect:zoomRect animated:YES];
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center
{
    CGRect zoomRect;
    if (scale == 0) {
        scale = 1;
    }
    zoomRect.size.height = self.frame.size.height / scale;
    zoomRect.size.width  = self.frame.size.width  / scale;
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageview;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [scrollView setZoomScale:scale animated:NO];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    return;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    return;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint touch = [[touches anyObject] locationInView:self.superview];
    
    _imageview.center = touch;
}

- (void)dealloc
{
    [_contentView removeFromSuperview];
    [_imageview removeFromSuperview];
}

@end
