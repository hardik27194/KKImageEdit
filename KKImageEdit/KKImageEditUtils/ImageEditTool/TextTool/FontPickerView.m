//
//  FontPickerView.m
//
//  Created by finger on 2015/12/14.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "FontPickerView.h"
#import "UIView+Extension.h"

const CGFloat kFontPickerViewConstantFontSize = 14;

@interface FontPickerView()<UIPickerViewDelegate, UIPickerViewDataSource>
{
    UIPickerView *_pickerView;
}

@property (nonatomic, strong) NSArray *fontList;
@property (nonatomic, strong) NSArray *fontSizes;

@end

@implementation FontPickerView

+ (NSArray*)allFontList
{
    NSMutableArray *list = [NSMutableArray array];
    
    for(NSString *familyName in [UIFont familyNames]){
        for(NSString *fontName in [UIFont fontNamesForFamilyName:familyName]){
            [list addObject:[UIFont fontWithName:fontName size:kFontPickerViewConstantFontSize]];
        }
    }
    
    return [list sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fontName" ascending:YES]]];
}

+ (NSArray*)defaultSizes
{
    return @[@8, @10, @12, @14, @16, @18, @20, @24, @28, @32, @38, @44, @50];
}

+ (UIFont*)defaultFont
{
    return [UIFont fontWithName:@"HiraKakuProN-W3"size:kFontPickerViewConstantFontSize];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.clipsToBounds = YES;
        
        _pickerView = [[UIPickerView alloc] initWithFrame:self.bounds];
        _pickerView.center = CGPointMake(self.width/2, self.height/2);
        _pickerView.backgroundColor = [UIColor clearColor];
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
        [self addSubview:_pickerView];
        
        self.fontList = [self.class allFontList];
        self.fontSizes = [self.class defaultSizes];
    }
    
    return self;
}

- (void)setFontList:(NSArray *)fontList
{
    if(fontList != _fontList){
        _fontList = fontList;
        [_pickerView reloadComponent:0];
    }
}

- (void)setFontSizes:(NSArray *)fontSizes
{
    if(fontSizes != _fontSizes){
        _fontSizes = fontSizes;
        [_pickerView reloadComponent:1];
    }
}

- (void)setFont:(UIFont *)font
{
    UIFont *tmp = [font fontWithSize:kFontPickerViewConstantFontSize];
    
    NSInteger fontIndex = [self.fontList indexOfObject:tmp];
    if(fontIndex==NSNotFound){ fontIndex = 0; }
    
    NSInteger sizeIndex = 0;
    for(sizeIndex=0; sizeIndex<self.fontSizes.count; sizeIndex++){
        if(font.pointSize<=[self.fontSizes[sizeIndex] floatValue]){
            break;
        }
    }
    
    [_pickerView selectRow:fontIndex inComponent:0 animated:NO];
    [_pickerView selectRow:sizeIndex inComponent:1 animated:NO];
}

- (UIFont*)font
{
    UIFont *font = self.fontList[[_pickerView selectedRowInComponent:0]];
    CGFloat size = [self.fontSizes[[_pickerView selectedRowInComponent:1]] floatValue];
    return [font fontWithSize:size];
}

#pragma mark- UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (component)
    {
        case 0:
            return self.fontList.count;
        case 1:
            return self.fontSizes.count;
    }
    return 0;
}

#pragma mark- UIPickerViewDelegate

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return self.height/4;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    CGFloat ratio = 0.8;
    switch (component)
    {
        case 0:
            return self.width*ratio;
        case 1:
            return self.width*(1-ratio);
    }
    return 0;
}

-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) {
        return ((UIFont *)[self.fontList objectAtIndex:row]).fontName;
    } else {
        return [NSString stringWithFormat:@"%@",self.fontSizes[row]];
    }
}

- (UIView*)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *lbl = nil;
    
    if([view isKindOfClass:[UILabel class]]){
        lbl = (UILabel*)view;
    }else{
        CGFloat W = [self pickerView:pickerView widthForComponent:component];
        CGFloat H = [self pickerView:pickerView rowHeightForComponent:component];
        CGFloat dx = 10;
        lbl = [[UILabel alloc] initWithFrame:CGRectMake(dx, 0, W-2*dx, H)];
        lbl.backgroundColor = [UIColor clearColor];
        lbl.adjustsFontSizeToFitWidth = YES;
        lbl.minimumScaleFactor = 0.5;
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.textColor = [UIColor whiteColor];
    }
    
    switch (component)
    {
        case 0:
        {
            lbl.font = self.fontList[row];
            lbl.text = [NSString stringWithFormat:@"%@", lbl.font.fontName];
            break;
        }
        case 1:
        {
            lbl.font = [UIFont systemFontOfSize:kFontPickerViewConstantFontSize];
            lbl.text = [NSString stringWithFormat:@"%@", self.fontSizes[row]];
            break;
        }
        default:
            break;
    }
    
    return lbl;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if([self.delegate respondsToSelector:@selector(fontPickerView:didSelectFont:)]){
        [self.delegate fontPickerView:self didSelectFont:self.font];
    }
}

@end
