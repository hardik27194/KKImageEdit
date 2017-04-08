//
//  FontPickerView.h
//
//  Created by finger on 2015/12/14.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FontPickerViewDelegate;

@interface FontPickerView : UIView
{
    
}

+ (NSArray*)allFontList;
+ (NSArray*)defaultSizes;
+ (UIFont*)defaultFont;

@property (nonatomic, weak) id<FontPickerViewDelegate> delegate;
@property (nonatomic, strong) UIFont *font;

@end


@protocol FontPickerViewDelegate <NSObject>
@optional
- (void)fontPickerView:(FontPickerView*)pickerView didSelectFont:(UIFont*)font;

@end
