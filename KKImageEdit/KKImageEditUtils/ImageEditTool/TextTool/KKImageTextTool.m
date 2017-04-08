//
//  KKImageTextTool.m
//  
//
//  Created by finger on 17/2/18.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "KKImageTextTool.h"
#import <UIKit/UIKit.h>
#import "CircleView.h"
#import "UIView+Extension.h"
#import "ColorPickerView.h"
#import "FontPickerView.h"
#import "TextEditView.h"
#import "KKImageEditToolItem.h"
#import "UIView+Extension.h"

typedef NS_ENUM(NSUInteger, MenuItemType)
{
    MenuItem_AddNew = 0 ,
    MenuItem_TextEdit,
    MenuItem_ColorEdit,
    MenuItem_FontEdit,
    MenuItem_AlignLeft,
    MenuItem_AlignCenter,
    MenuItem_AlignRight
};

typedef NS_ENUM(NSUInteger, SettingViewIndex)
{
    SETTING_TEXTVIEW,
    SETTING_COLORVIEW,
    SETTING_FONTVIEW
};

#pragma mark ----------------TextLabel--------------------------

@interface TextLabel : UILabel
{
    
}

@property (nonatomic, strong) UIColor *outlineColor;
@property (nonatomic, assign) CGFloat outlineWidth;

@end

@implementation TextLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)setOutlineColor:(UIColor *)outlineColor
{
    if(outlineColor != _outlineColor){
        _outlineColor = outlineColor;
        [self setNeedsDisplay];
    }
}

- (void)setOutlineWidth:(CGFloat)outlineWidth
{
    if(outlineWidth != _outlineWidth){
        _outlineWidth = outlineWidth;
        [self setNeedsDisplay];
    }
}

- (void)drawTextInRect:(CGRect)rect
{
    CGSize shadowOffset = self.shadowOffset;
    
    UIColor *txtColor = self.textColor;
    
    CGFloat outlineSize = self.outlineWidth * self.font.pointSize * 0.3;
    
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(contextRef, outlineSize);
    CGContextSetLineJoin(contextRef, kCGLineJoinRound);
    
    CGContextSetTextDrawingMode(contextRef, kCGTextStroke);
    self.textColor = self.outlineColor;
    [super drawTextInRect:CGRectInset(rect, outlineSize/4, outlineSize/4)];
    
    CGContextSetTextDrawingMode(contextRef, kCGTextFill);
    self.textColor = txtColor;
    [super drawTextInRect:CGRectInset(rect, outlineSize/4, outlineSize/4)];
    
    self.shadowOffset = shadowOffset;
}

@end


#pragma mark ----------------TextView--------------------------


@protocol TextViewDelegate;

@interface TextView : UIView
{
    TextLabel *_label;
    UIButton *_deleteButton;
    CircleView *_circleView;
    
    CGFloat _scale;
    CGFloat _arg;
    
    CGPoint _initialPoint;
    CGFloat _initialArg;
    CGFloat _initialScale;
}

@property (nonatomic, weak)id<TextViewDelegate>delegate;

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) NSTextAlignment textAlignment;

+ (void)setActiveTextView:(TextView*)view;

- (void)setScale:(CGFloat)scale;
- (void)sizeToFitWithMaxWidth:(CGFloat)width lineHeight:(CGFloat)lineHeight;

@end

@protocol TextViewDelegate <NSObject>

- (void)textViewDidSelected:(TextView *)textView;

@end

const CGFloat MAX_FONT_SIZE = 50.0;

#pragma mark- TextView

@implementation TextView

+ (void)setActiveTextView:(TextView*)view
{
    static TextView *activeView = nil;
    
    if(view != activeView){
        
        [activeView setAvtive:NO];
        activeView = view;
        [activeView setAvtive:YES];
        
        [activeView.superview bringSubviewToFront:activeView];
        
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(0, 0, 132, 132)];
    
    if(self){
        
        _arg = 0;
        _scale = 1 ;
        
        [self initLabel];
        [self initDeleteBtn];
        [self initCircleView];
    }
    
    return self;
}

- (void)initLabel
{
    _label = [[TextLabel alloc] init];
    _label.textColor = [UIColor whiteColor];
    _label.numberOfLines = 0;
    _label.backgroundColor = [UIColor clearColor];
    _label.layer.borderColor = [[UIColor redColor] CGColor];
    _label.layer.cornerRadius = 3;
    _label.font = [UIFont systemFontOfSize:MAX_FONT_SIZE];
    _label.minimumScaleFactor = 1/MAX_FONT_SIZE;
    _label.adjustsFontSizeToFitWidth = YES;
    _label.textAlignment = NSTextAlignmentCenter;
    
    [self setText:@"Text"];
    [self setFillColor:[UIColor redColor]];
    [self setBorderColor:[UIColor redColor]];
    [self setBorderWidth:0.0];
    [self setTextAlignment:NSTextAlignmentCenter];
    [self setFont:[UIFont systemFontOfSize:17.0]];
    
    CGSize size = [_label sizeThatFits:CGSizeMake(FLT_MAX, FLT_MAX)];
    _label.frame = CGRectMake(16, 16, size.width, size.height);
    self.frame = CGRectMake(0, 0, size.width + 32, size.height + 32);
    
    [self addSubview:_label];
    
    _label.userInteractionEnabled = YES;
    [_label addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidTap:)]];
    [_label addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidPan:)]];
}

- (void)initDeleteBtn
{
    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _deleteButton.frame = CGRectMake(0, 0, 20, 20);
    _deleteButton.center = _label.frame.origin;
    [_deleteButton addTarget:self action:@selector(pushedDeleteBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_deleteButton setImage:[UIImage imageNamed:@"btn_delete"] forState:UIControlStateNormal];
    [self addSubview:_deleteButton];
}

- (void)initCircleView
{
    _circleView = [[CircleView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    _circleView.center = CGPointMake(_label.width + _label.left, _label.height + _label.top);
    _circleView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    _circleView.radius = 0.7;
    _circleView.color = [UIColor redColor];
    [_circleView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(circleViewDidPan:)]];
    [self addSubview:_circleView];
}

#pragma mark -- hitTest

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView* view= [super hitTest:point withEvent:event];
    if(view==self){
        return nil;
    }
    return view;
}

#pragma mark -- 设置是否选中

- (void)setAvtive:(BOOL)active
{
    _deleteButton.hidden = !active;
    _circleView.hidden = !active;
    _label.layer.borderWidth = (active) ? 1/_scale : 0;
}

- (BOOL)active
{
    return !_deleteButton.hidden;
}

- (void)sizeToFitWithMaxWidth:(CGFloat)width lineHeight:(CGFloat)lineHeight
{
    self.transform = CGAffineTransformIdentity;
    _label.transform = CGAffineTransformIdentity;
    
    CGSize size = [_label sizeThatFits:CGSizeMake(width / (15/MAX_FONT_SIZE), FLT_MAX)];
    _label.frame = CGRectMake(16, 16, size.width, size.height);
    
    CGFloat viewW = (_label.width + 32);
    CGFloat viewH = _label.font.lineHeight;
    
    CGFloat ratio = MIN(width / viewW, lineHeight / viewH);
    
    [self setScale:ratio];
}

- (void)setScale:(CGFloat)scale
{
    _scale = scale;
    
    self.transform = CGAffineTransformIdentity;
    
    _label.transform = CGAffineTransformMakeScale(_scale, _scale);
    
    CGRect rct = self.frame;
    rct.origin.x += (rct.size.width - (_label.width + 32)) / 2;
    rct.origin.y += (rct.size.height - (_label.height + 32)) / 2;
    rct.size.width  = _label.width + 32;
    rct.size.height = _label.height + 32;
    self.frame = rct;
    
    _label.center = CGPointMake(rct.size.width/2, rct.size.height/2);
    
    self.transform = CGAffineTransformMakeRotation(_arg);
    
    _label.layer.borderWidth = 1/_scale;
    _label.layer.cornerRadius = 3/_scale;
}

- (void)setFillColor:(UIColor *)fillColor
{
    _label.textColor = fillColor;
}

- (UIColor*)fillColor
{
    return _label.textColor;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _label.outlineColor = borderColor;
}

- (UIColor*)borderColor
{
    return _label.outlineColor;
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    _label.outlineWidth = borderWidth;
}

- (CGFloat)borderWidth
{
    return _label.outlineWidth;
}

- (void)setFont:(UIFont *)font
{
    _label.font = [font fontWithSize:MAX_FONT_SIZE];
}

- (UIFont*)font
{
    return _label.font;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    _label.textAlignment = textAlignment;
}

- (NSTextAlignment)textAlignment
{
    return _label.textAlignment;
}

- (void)setText:(NSString *)text
{
    if(![text isEqualToString:_text]){
        _text = text;
        _label.text = (_text.length>0) ? _text : @"Text";
    }
}

#pragma mark -- 删除

- (void)pushedDeleteBtn:(id)sender
{
    TextView *nextTarget = nil;
    
    const NSInteger index = [self.superview.subviews indexOfObject:self];
    
    for(NSInteger i=index+1; i<self.superview.subviews.count; ++i){
        UIView *view = [self.superview.subviews objectAtIndex:i];
        if([view isKindOfClass:[TextView class]]){
            nextTarget = (TextView*)view;
            break;
        }
    }
    
    if(nextTarget==nil){
        for(NSInteger i=index-1; i>=0; --i){
            UIView *view = [self.superview.subviews objectAtIndex:i];
            if([view isKindOfClass:[TextView class]]){
                nextTarget = (TextView*)view;
                break;
            }
        }
    }
    
    [[self class] setActiveTextView:nextTarget];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(textViewDidSelected:)]){
        [self.delegate textViewDidSelected:nextTarget];
    }
    
    [self removeFromSuperview];
}

#pragma mark -- gesture events

- (void)viewDidTap:(UITapGestureRecognizer*)sender
{
    [[self class] setActiveTextView:self];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(textViewDidSelected:)]){
        [self.delegate textViewDidSelected:self];
    }
}

- (void)viewDidPan:(UIPanGestureRecognizer*)sender
{
    [[self class] setActiveTextView:self];
    
    CGPoint p = [sender translationInView:self.superview];
    
    if(sender.state == UIGestureRecognizerStateBegan){
        _initialPoint = self.center;
    }
    self.center = CGPointMake(_initialPoint.x + p.x, _initialPoint.y + p.y);
}

- (void)circleViewDidPan:(UIPanGestureRecognizer*)sender
{
    CGPoint p = [sender translationInView:self.superview];
    
    static CGFloat tmpR = 1;
    static CGFloat tmpA = 0;
    
    if(sender.state == UIGestureRecognizerStateBegan){
        
        _initialPoint = [self.superview convertPoint:_circleView.center fromView:_circleView.superview];
        
        CGPoint p = CGPointMake(_initialPoint.x - self.center.x, _initialPoint.y - self.center.y);
        tmpR = sqrt(p.x*p.x + p.y*p.y);
        tmpA = atan2(p.y, p.x);
        
        _initialArg = _arg;
        _initialScale = _scale;
        
    }
    
    p = CGPointMake(_initialPoint.x + p.x - self.center.x, _initialPoint.y + p.y - self.center.y);
    CGFloat R = sqrt(p.x*p.x + p.y*p.y);
    CGFloat arg = atan2(p.y, p.x);
    
    _arg   = _initialArg + arg - tmpA;
    
    [self setScale:MAX(_initialScale * R / tmpR, 15/MAX_FONT_SIZE)];
}

@end



#pragma mark ----------------KKImageTextTool--------------------------


@interface KKImageTextTool()<ColorPickerViewDelegate, FontPickerViewDelegate, TextEditViewDelegate,UIScrollViewDelegate,KKImageEditToolItemDelegate,TextViewDelegate>
{
    UIView *superView;
    UIView *superMenuView;
    
    UIImage *_originalImage;
    
    UIView *_workingView;
    
    UIScrollView *_settingView;
    ColorPickerView *colorPicker;
    FontPickerView *fontPicker;
    TextEditView *textEditView;
    
    UIScrollView *_menuScroll;
    
    KKImageEditToolItem *_textItem;
    KKImageEditToolItem *_colorItem;
    KKImageEditToolItem *_fontItem;
    KKImageEditToolItem *_alignLeftItem;
    KKImageEditToolItem *_alignCenterItem;
    KKImageEditToolItem *_alignRightItem;
}

@property (nonatomic, strong) TextView *selectedTextView;

@end


@implementation KKImageTextTool

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image
{
    superView = view ;
    superMenuView = menuView ;
    
    _originalImage = image;
    
    _menuScroll = [[UIScrollView alloc] initWithFrame:menuView.bounds];
    _menuScroll.backgroundColor = [UIColor blackColor];
    _menuScroll.showsHorizontalScrollIndicator = NO;
    [menuView addSubview:_menuScroll];
    _menuScroll.transform = CGAffineTransformMakeTranslation(0,_menuScroll.height);
    [UIView animateWithDuration:0.3 animations:^{
        _menuScroll.transform = CGAffineTransformIdentity;
    }];
    
    _workingView = [[UIView alloc] initWithFrame:frame];
    _workingView.clipsToBounds = YES;
    _workingView.userInteractionEnabled = YES ;
    [_workingView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidTap:)]];
    [view addSubview:_workingView];
    
    _settingView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, view.width, 180)];
    _settingView.layer.cornerRadius = 5 ;
    _settingView.clipsToBounds = YES ;
    _settingView.y = superMenuView.y - _settingView.height;
    _settingView.backgroundColor = [UIColor blackColor];
    _settingView.delegate = self;
    _settingView.hidden = YES ;
    _settingView.scrollEnabled = NO ;
    [view addSubview:_settingView];
    
    [self setMenu];
    [self setMenuBtnEnabled:false];
    [self setSetingView];
}

- (void)cleanup
{
    [_settingView removeFromSuperview];
    [_workingView removeFromSuperview];
    
    [UIView animateWithDuration:0.3 animations:^{
        _menuScroll.transform = CGAffineTransformMakeTranslation(0, _menuScroll.height);
    }completion:^(BOOL finished) {
        [_menuScroll removeFromSuperview];
    }];
}

#pragma mark -- 生成最终图片

- (void)genEditTextImageWithBlock:(void (^)(UIImage *))completionBlock
{
    [TextView setActiveTextView:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self buildImage:_originalImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image);
        });
    });
}

- (UIImage*)buildImage:(UIImage*)image
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    
    [image drawAtPoint:CGPointZero];
    
    CGFloat scale = image.size.width / _workingView.width;
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), scale, scale);
    [_workingView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

#pragma mark -- 初始化菜单栏

- (void)setMenu
{
    CGFloat x = 0;
    CGFloat W = 50;
    CGFloat H = _menuScroll.height;
    CGFloat padding = 5 ;
    
    NSArray *_menu = @[
                       @{@"title":@"New", @"name":[NSNumber numberWithInt:MenuItem_AddNew]},
                       @{@"title":@"Text", @"name":[NSNumber numberWithInt:MenuItem_TextEdit]},
                       @{@"title":@"Color",@"name":[NSNumber numberWithInt:MenuItem_ColorEdit]},
                       @{@"title":@"Font", @"name":[NSNumber numberWithInt:MenuItem_FontEdit]},
                       @{@"title":@"", @"name":[NSNumber numberWithInt:MenuItem_AlignLeft]},
                       @{@"title":@"", @"name":[NSNumber numberWithInt:MenuItem_AlignCenter]},
                       @{@"title":@"", @"name":[NSNumber numberWithInt:MenuItem_AlignRight]},
                       ];
    
    for(NSDictionary *obj in _menu){
        
        MenuItemType type = [obj[@"name"]integerValue];
        
        KKImageEditToolItem *view = [[KKImageEditToolItem alloc]initWithFrame:CGRectMake(x, 0, W, H)];
        view.delegate = self ;
        view.itemTitle = obj[@"title"];
        view.editInfo = obj;
        
        switch (type)
        {
            case MenuItem_AddNew:
            {
                view.itemImage = [UIImage imageNamed:@"btn_add"];
                
                break ;
            }
            case MenuItem_TextEdit:
            {
                _textItem = view;
                _textItem.itemImage = [UIImage imageNamed:@"text"];
                
                break;
            }
            case MenuItem_ColorEdit:
            {
                _colorItem = view;
                _colorItem.itemImageView.backgroundColor = [UIColor clearColor];
                _colorItem.itemImageView.layer.borderColor = [UIColor whiteColor].CGColor;
                _colorItem.itemImageView.layer.borderWidth = 2;
                
                break;
            }
            case MenuItem_FontEdit:
            {
                _fontItem = view;
                _fontItem.itemImage = [UIImage imageNamed:@"btn_font"];
                
                break;
            }
            case MenuItem_AlignLeft:
            {
                _alignLeftItem = view;
                _alignLeftItem.itemImage = [UIImage imageNamed:@"btn_align_left"];
                
                break;
            }
            case MenuItem_AlignCenter:
            {
                _alignCenterItem = view;
                _alignCenterItem.itemImage = [UIImage imageNamed:@"btn_align_center"];
                
                break;
            }
            case MenuItem_AlignRight:
            {
                _alignRightItem = view;
                _alignRightItem.itemImage = [UIImage imageNamed:@"btn_align_right"];
                
                break;
            }
        }
        
        [_menuScroll addSubview:view];
        
        x += (W + padding);
    }
    
    _menuScroll.contentSize = CGSizeMake(MAX(x, _menuScroll.frame.size.width+1), 0);
}

- (void)setMenuBtnEnabled:(BOOL)enabled
{
    _textItem.userInteractionEnabled =
    _colorItem.userInteractionEnabled =
    _fontItem.userInteractionEnabled =
    _alignLeftItem.userInteractionEnabled =
    _alignCenterItem.userInteractionEnabled =
    _alignRightItem.userInteractionEnabled = enabled;
    
    _textItem.alpha =
    _colorItem.alpha =
    _fontItem.alpha =
    _alignLeftItem.alpha =
    _alignCenterItem.alpha =
    _alignRightItem.alpha = (enabled ? 1 : 0.5);
}

#pragma mark -- KKImageEditToolItemDelegate

- (void)imageEditItem:(KKImageEditToolItem *)item clickItemWithType:(KKImageEditType)editType editInfo:(NSDictionary *)editInfo
{
    MenuItemType type = [[editInfo objectForKey:@"name"]integerValue];
    
    switch (type)
    {
        case MenuItem_AddNew:
        {
            [self addNewText];
            [self hideSettingView];
            break;
        }
        case MenuItem_TextEdit:
        {
            if(self.selectedTextView){
                [self showEditTextViewWithTextView:self.selectedTextView];
            }
            
            [self hideSettingView];
            
            break ;
        }
        case MenuItem_ColorEdit:
        case MenuItem_FontEdit:
        {
            [self showSettingViewWithMenuType:type];
            break;
        }
        case MenuItem_AlignLeft:
        {
            [self setTextAlignment:NSTextAlignmentLeft];
            [self hideSettingView];
            break;
        }
        case MenuItem_AlignCenter:
        {
            [self setTextAlignment:NSTextAlignmentCenter];
            [self hideSettingView];
            break;
        }
        case MenuItem_AlignRight:
        {
            [self setTextAlignment:NSTextAlignmentRight];
            [self hideSettingView];
            break;
        }
    }
}

#pragma mark -- 初始化设置视图

- (void)setSetingView
{
    colorPicker = [[ColorPickerView alloc]initWithFrame:CGRectMake(0, 0, _settingView.width, _settingView.height)];
    colorPicker.delegate = self;
    [_settingView addSubview:colorPicker];
    
    fontPicker = [[FontPickerView alloc]initWithFrame:CGRectMake(_settingView.width, 0, _settingView.width, _settingView.height)];
    fontPicker.delegate = self ;
    [_settingView addSubview:fontPicker];
    
    _settingView.contentSize = CGSizeMake(2 * _settingView.width, 0);
}

#pragma mark -- 选中某个文字视图

- (void)setSelectedTextView:(TextView *)selectedTextView
{
    if(selectedTextView != _selectedTextView){
        _selectedTextView = selectedTextView;
    }
    
    [self hideSettingView];
    
    if(_selectedTextView == nil){
        
        _alignLeftItem.selected = _alignCenterItem.selected = _alignRightItem.selected = NO;
        
        _colorItem.itemImageView.backgroundColor = [UIColor clearColor];
        _colorItem.itemImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        _colorItem.itemImageView.layer.borderWidth = 2;
        
        [self setMenuBtnEnabled:NO];
        
    }else{
        
        [self setMenuBtnEnabled:YES];
        
        colorPicker.fillColor = selectedTextView.fillColor;
        colorPicker.pathWith = selectedTextView.borderWidth;
        colorPicker.pathColor = selectedTextView.borderColor;
        
        fontPicker.font = selectedTextView.font;
        
        _colorItem.itemImageView.backgroundColor = selectedTextView.fillColor;
        _colorItem.itemImageView.layer.borderColor = selectedTextView.borderColor.CGColor;
        _colorItem.itemImageView.layer.borderWidth = MAX(2, 10*selectedTextView.borderWidth);
        
        _alignLeftItem.selected = _alignCenterItem.selected = _alignRightItem.selected = NO;
        
        NSTextAlignment align = self.selectedTextView.textAlignment;
        if(align == NSTextAlignmentLeft){
            _alignLeftItem.selected = YES ;
        }else if(align == NSTextAlignmentCenter){
            _alignCenterItem.selected = YES ;
        }else if(align == NSTextAlignmentRight){
            _alignRightItem.selected = YES;
        }
        
    }
}

#pragma mark -- 添加新的文字

- (void)addNewText
{
    TextView *view = [[TextView alloc] init];
    
    CGFloat ratio = MIN( (0.8 * _workingView.width) / view.width, (0.2 * _workingView.height) / view.height);
    [view setScale:ratio];
    
    view.center = CGPointMake(_workingView.center.x, _workingView.frame.origin.y + view.frame.size.height - 20);
    
    view.delegate = self ;
    
    self.selectedTextView = view ;
    
    [_workingView addSubview:view];
    
    [TextView setActiveTextView:view];
    
    [self showEditTextViewWithTextView:view];
}

- (void)showEditTextViewWithTextView:(TextView *)textview
{
    textEditView = [[TextEditView alloc]init];
    textEditView.delegate = self ;
    textEditView.text = textview.text ;
    textEditView.textFont = textview.font;
    textEditView.textColor = textview.fillColor;
    
    [[[[UIApplication sharedApplication]delegate] window] addSubview:textEditView];
    textEditView.y = [[UIScreen mainScreen]bounds].size.height;
    [UIView animateWithDuration:0.5 animations:^{
        textEditView.y = 0 ;
    }];
}

#pragma mark -- 显示隐藏设置界面

- (void)hideSettingView
{
    [UIView animateWithDuration:0.3 animations:^{
        
        CGRect frame = _settingView.frame ;
        frame.origin.y = superMenuView.y;
        _settingView.frame = frame ;
        
    } completion:^(BOOL finished) {
        
        _settingView.hidden = YES;
        
        CGRect frame = _settingView.frame ;
        frame.origin.y = superMenuView.y - _settingView.height ;
        _settingView.frame = frame ;
        
    }];
    
}

- (void)showSettingViewWithMenuType:(MenuItemType)type
{
    if(_settingView.hidden){
        
        CGRect frame = _settingView.frame ;
        frame.origin.y = superMenuView.y ;
        [_settingView setFrame:frame] ;
        [_settingView setHidden:NO];
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = _settingView.frame ;
            frame.origin.y = superMenuView.y - _settingView.height ;
            _settingView.frame = frame ;
        }];
        
        if(type == MenuItem_ColorEdit){
            [_settingView setContentOffset:CGPointZero animated:NO];
        }else if(type == MenuItem_FontEdit){
            [_settingView setContentOffset:CGPointMake(_settingView.width, 0) animated:NO];
        }
        
    }else{
        
        if(type == MenuItem_ColorEdit){
            [_settingView setContentOffset:CGPointZero animated:YES];
        }else if(type == MenuItem_FontEdit){
            [_settingView setContentOffset:CGPointMake(_settingView.width, 0) animated:YES];
        }
        
    }
}

- (void)setTextAlignment:(NSTextAlignment)alignment
{
    self.selectedTextView.textAlignment = alignment;
    
    _alignLeftItem.selected = _alignCenterItem.selected = _alignRightItem.selected = NO;
    
    switch (alignment)
    {
        case NSTextAlignmentLeft:
        {
            _alignLeftItem.selected = YES;
            break;
        }
        case NSTextAlignmentCenter:
        {
            _alignCenterItem.selected = YES;
            break;
        }
        case NSTextAlignmentRight:
        {
            _alignRightItem.selected = YES;
            break;
        }
        default:break;
    }
}

#pragma mark -- ColorPickerViewDelegate

- (void)colorPickerView:(ColorPickerView *)picker color:(UIColor *)color type:(SetColorType)type
{
    if(type == SetColorTypeFill){
        
        self.selectedTextView.fillColor = color;
        
        _colorItem.itemImageView.backgroundColor = color;
        
    }else if(type == SetColorTypePath){
        
        self.selectedTextView.borderColor = color;
        
        _colorItem.itemImageView.layer.borderColor = color.CGColor;
        
    }
}

- (void)colorPickerView:(ColorPickerView *)picker colorPathWithChange:(CGFloat)borderWidth
{
    self.selectedTextView.borderWidth = borderWidth;
    
    _colorItem.itemImageView.layer.borderWidth = MAX(2, 10*borderWidth);;
}

#pragma mark -- FontPickerViewDelegate

- (void)fontPickerView:(FontPickerView *)pickerView didSelectFont:(UIFont *)font
{
    self.selectedTextView.font = font;
    [self.selectedTextView sizeToFitWithMaxWidth:0.8*_workingView.width lineHeight:0.2*_workingView.height];
}

#pragma mark -- TextEditViewDelegate

- (void)textEditCompleteWithText:(NSString *)text
{
    self.selectedTextView.text = text ;
    [self.selectedTextView sizeToFitWithMaxWidth:0.8*_workingView.width lineHeight:0.2*_workingView.height];
}

#pragma mark -- TextViewDelegate

- (void)textViewDidSelected:(TextView *)textView
{
    self.selectedTextView = textView ;
}

#pragma mark -- gesture events

- (void)viewDidTap:(UITapGestureRecognizer*)sender
{
    [self hideSettingView];
}

@end
