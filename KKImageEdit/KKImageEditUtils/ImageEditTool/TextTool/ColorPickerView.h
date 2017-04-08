//
//  ColorPickerView.h
//
//  Created by finger on 2015/12/13.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger , SetColorType){
    SetColorTypeFill,
    SetColorTypePath
};

@protocol ColorPickerViewDelegate;

@interface ColorPickerView : UIView
{
    
}

@property (nonatomic, weak) id<ColorPickerViewDelegate> delegate;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) UIColor *pathColor;
@property (nonatomic, assign) CGFloat pathWith;

@end


@protocol ColorPickerViewDelegate <NSObject>
@optional
- (void)colorPickerView:(ColorPickerView*)picker color:(UIColor*)color type:(SetColorType)type;
- (void)colorPickerView:(ColorPickerView*)picker colorPathWithChange:(CGFloat)borderWidth;
@end
