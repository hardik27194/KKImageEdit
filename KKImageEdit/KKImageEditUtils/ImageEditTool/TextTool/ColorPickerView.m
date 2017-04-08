//
//  ColorPickerView.m
//
//  Created by finger on 2015/12/13.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "ColorPickerView.h"
#import "CircleView.h"
#import "UIView+Extension.h"

@protocol ColorCircleViewDelegate;

@interface ColorCircleView : UIView
{
    
}

@property (nonatomic, weak) id<ColorCircleViewDelegate> delegate;

- (UIColor*)color;
- (void)setColor:(UIColor*)color;

@end

@protocol ColorCircleViewDelegate <NSObject>
@optional
- (void)colorValueDidChange:(ColorCircleView*)view;
@end


@implementation ColorCircleView
{
    CircleView *_circleView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if(self){
        
        self.backgroundColor = [UIColor clearColor];
        
        _circleView = [[CircleView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _circleView.radius = 0.6;
        _circleView.color = [UIColor blackColor];
        _circleView.center = CGPointMake(frame.size.width/2, frame.size.width/2);
        [self addSubview:_circleView];
        
        [_circleView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(circleViewDidPan:)]];
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidTap:)]];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [self setNeedsDisplay];
}

- (CGFloat)hue
{
    CGPoint point = _circleView.center;
    
    point.x -= self.center.x;
    point.y -= self.center.y;
    CGFloat theta = atan2f(point.y, point.x);
    
    return (theta>0)?theta/(2*M_PI):1+theta/(2*M_PI);
}

- (CGFloat)brightness
{
    CGPoint point = _circleView.center;
    CGFloat R = self.circleRadius;
    
    point.x -= self.center.x;
    point.y -= self.center.y;
    
    return MIN(1, sqrtf(point.x*point.x+point.y*point.y)/R);
}

- (UIColor*)color
{
    return _circleView.color;
}

- (void)setColor:(UIColor *)color
{
    CGFloat H, S, B, A;
    
    if([color getHue:&H saturation:&S brightness:&B alpha:&A]){
        [self setColorWithHue:H saturation:S brightness:B alpha:A];
    }else if([color getWhite:&S alpha:&A]){
        [self setColorWithHue:0 saturation:S brightness:S alpha:A];
    }
    [self setNeedsDisplay];
}

- (void)setColorWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha
{
    CGFloat theta = hue * 2 * M_PI;
    CGFloat R = self.circleRadius * brightness;
    
    _circleView.center = CGPointMake(R*cosf(theta) + self.center.x, R*sinf(theta) + self.center.y);
    
    [self colorStateDidChange];
}

#pragma mark -- 圆圈半径，占整个视图宽或高的比例

- (CGFloat)circleRadius
{
    return 0.80 * MIN(self.frame.size.width, self.frame.size.height)/2;
}

- (void)drawRect:(CGRect)rect
{
    CGFloat R = self.circleRadius;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 0.1 * R);
    
    CGFloat div = 360.0;
    for(int i=0;i<div;i++){
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithHue:i/div saturation:1.0 brightness:1.0 alpha:1].CGColor);
        CGContextAddArc(context, self.center.x, self.center.y, R, i/div*2*M_PI, (i+1.5)/div*2*M_PI, 0);
        CGContextStrokePath(context);
    }
}

- (void)viewDidTap:(UITapGestureRecognizer*)sender
{
    CGPoint point = [sender locationInView:self];
    
    [self setCircleViewToPoint:point];
}

- (void)circleViewDidPan:(UIPanGestureRecognizer*)sender
{
    CGPoint point = [sender locationInView:self];
    
    [self setCircleViewToPoint:point];
}

- (void)setCircleViewToPoint:(CGPoint)point
{
    CGFloat R = self.circleRadius;
    
    point.x -= self.center.x;
    point.y -= self.center.y;
    CGFloat theta = atan2f(point.y, point.x);
    CGFloat radius= MIN(R, sqrtf(point.x*point.x+point.y*point.y));
    _circleView.center = CGPointMake(radius*cosf(theta) + self.center.x, radius*sinf(theta) + self.center.y);
    
    [self colorStateDidChange];
}

- (void)colorStateDidChange
{
    _circleView.color = [UIColor colorWithHue:self.hue saturation:1.0 brightness:self.brightness alpha:1.0];
    
    if([self.delegate respondsToSelector:@selector(colorValueDidChange:)]){
        [self.delegate colorValueDidChange:self];
    }
}

@end




#pragma mark- ColorPickerView

@interface ColorPickerView()<ColorCircleViewDelegate>
{
    ColorCircleView *_colorCircle;
    
    CircleView *_fillCircle;//字体颜色
    UILabel *_filllabel ;
    
    CircleView *_pathCircle;//字体边缘颜色
    UILabel *_pathLabel ;
    
    UILabel *_pathSliderLabel;
    UISlider *_pathSlider;//边缘颜色的宽度
    
    SetColorType setColorType;
}
@end

@implementation ColorPickerView

- (id)init
{
    self = [self initWithFrame:CGRectMake(0, 0, 0, 180)];
    if(self){
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customeInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self customeInit];
}

- (void)customeInit
{
    CGFloat W = 120;
    
    _colorCircle = [[ColorCircleView alloc] initWithFrame:CGRectMake(0, 0, W, W)];
    _colorCircle.delegate = self;
    _colorCircle.color = [UIColor redColor];
    [self addSubview:_colorCircle];
    
    NSInteger lableW = 70 ;
    NSInteger labelH = 40 ;
    
    _filllabel = [[UILabel alloc]initWithFrame:CGRectMake(self.width - lableW - 5, W / 2 - labelH - 5, lableW, labelH)];
    _filllabel.textAlignment = NSTextAlignmentLeft ;
    _filllabel.textColor = [UIColor whiteColor];
    _filllabel.font = [UIFont systemFontOfSize:15.0];
    _filllabel.text = @"字体颜色";
    [self addSubview:_filllabel];
    
    int r = (arc4random() % 256) ;
    int g = (arc4random() % 256) ;
    int b = (arc4random() % 256) ;
    
    _fillCircle = [[CircleView alloc] initWithFrame:CGRectMake(_filllabel.x - labelH - 5, _filllabel.y, labelH, labelH)];
    _fillCircle.radius = 0.6;
    _filllabel.tag = SetColorTypeFill;
    _fillCircle.color = [UIColor redColor];
    _fillCircle.backgroundColor = [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
    [_fillCircle addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(colorTypeTapped:)]];
    [self addSubview:_fillCircle];
    
    _pathLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.width - lableW - 5, W / 2 + 5, lableW, labelH)];
    _pathLabel.textAlignment = NSTextAlignmentLeft ;
    _pathLabel.textColor = [UIColor whiteColor];
    _pathLabel.font = [UIFont systemFontOfSize:15.0];
    _pathLabel.text = @"边缘颜色";
    [self addSubview:_pathLabel];
    
    _pathCircle = [[CircleView alloc] initWithFrame:CGRectMake(_pathLabel.x - labelH - 5, _pathLabel.y, labelH, labelH)];
    _pathCircle.radius = 0.6;
    _pathCircle.borderWidth = 5;
    _pathCircle.borderColor = [UIColor whiteColor];
    _pathCircle.color = [UIColor clearColor];
    _pathCircle.tag = SetColorTypePath;
    _pathCircle.backgroundColor = [UIColor clearColor];
    [_pathCircle addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(colorTypeTapped:)]];
    [self addSubview:_pathCircle];
    
    NSInteger interval = 5 ;
    NSInteger sliderW = 190 ;
    NSInteger startX = 15;//(self.width - sliderW - lableW - interval ) / 2 ;
    
    _pathSliderLabel = [[UILabel alloc]initWithFrame:CGRectMake(startX, _colorCircle.height + 10, lableW, labelH)];
    _pathSliderLabel.textAlignment = NSTextAlignmentLeft ;
    _pathSliderLabel.textColor = [UIColor whiteColor];
    _pathSliderLabel.font = [UIFont systemFontOfSize:15.0];
    _pathSliderLabel.text = @"边缘宽度";
    [self addSubview:_pathSliderLabel];
    
    _pathSlider = [[UISlider alloc] initWithFrame:CGRectMake(_pathSliderLabel.x + _pathSliderLabel.width + interval, _pathSliderLabel.y, sliderW, labelH)];
    [_pathSlider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    _pathSlider.minimumValue = 0;
    _pathSlider.maximumValue = 1;
    _pathSlider.value = 0;
    [_pathSlider addTarget:self action:@selector(pathSliderDidChange:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_pathSlider];
    
    setColorType = SetColorTypeFill ;
    
    _colorCircle.color = _fillCircle.color;
    
    self.height = _pathSlider.y + _pathSlider.height + 10 ;
}

- (void)setColor:(UIColor *)color
{
    _colorCircle.color = color;
}

- (UIColor*)color
{
    return _colorCircle.color;
}

- (void)setFillColor:(UIColor *)fillColor
{
    _fillCircle.color = fillColor ;
    
    if(setColorType == SetColorTypeFill){
        _colorCircle.color = fillColor;
    }
}

- (UIColor *)fillColor
{
    return _fillCircle.color;
}

- (void)setPathColor:(UIColor *)pathColor
{
    _pathCircle.borderColor = pathColor;
    
    if(setColorType == SetColorTypePath){
        _colorCircle.color = pathColor;
    }
}

- (UIColor *)pathColor
{
    return _pathCircle.borderColor;
}

- (void)setPathWith:(CGFloat)pathWith
{
    _pathSlider.value = pathWith;
}

- (CGFloat)pathWith
{
    return _pathSlider.value ;
}

#pragma mark -- ColorCircleViewDelegate

- (void)colorValueDidChange:(ColorCircleView*)view
{
    if([self.delegate respondsToSelector:@selector(colorPickerView:color:type:)]){
        [self.delegate colorPickerView:self color:view.color type:setColorType];
    }
    
    if(setColorType == SetColorTypePath){
        _pathCircle.borderColor = view.color ;
        _fillCircle.backgroundColor = [UIColor clearColor];
    }else{
        _fillCircle.color = view.color ;
        _pathCircle.backgroundColor = [UIColor clearColor];
    }
    
}

#pragma mark -- UIGestureRecognizer

- (void)colorTypeTapped:(UITapGestureRecognizer*)sender
{
    SetColorType type = sender.view.tag ;
    if(setColorType == type){
        return ;
    }
    setColorType = type ;
    
    int r = (arc4random() % 256) ;
    int g = (arc4random() % 256) ;
    int b = (arc4random() % 256) ;
    
    if(setColorType == SetColorTypePath){
        _colorCircle.color = _pathCircle.borderColor;
        _pathCircle.backgroundColor = [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
        _fillCircle.backgroundColor = [UIColor clearColor];
    }else{
        _colorCircle.color = _fillCircle.color;
        _fillCircle.backgroundColor = [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
        _pathCircle.backgroundColor = [UIColor clearColor];
    }
    
}

#pragma mark -- UISlider event

- (void)pathSliderDidChange:(UISlider*)sender
{
    if([self.delegate respondsToSelector:@selector(colorPickerView:colorPathWithChange:)]){
        [self.delegate colorPickerView:self colorPathWithChange:_pathSlider.value];
    }
}

@end
