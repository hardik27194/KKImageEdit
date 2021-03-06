//
//  TextEditView.h
//  
//
//  Created by finger on 17/2/18.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TextEditViewDelegate <NSObject>
- (void)textEditCompleteWithText:(NSString *)text;
@end

@interface TextEditView : UIView

@property(nonatomic,weak)id<TextEditViewDelegate>delegate;
@property(nonatomic)NSString *text;
@property(nonatomic)UIColor *textColor;
@property(nonatomic)UIFont *textFont;

@end
