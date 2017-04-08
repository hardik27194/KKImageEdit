//
//  TextEditView.m
//  
//
//  Created by finger on 17/2/18.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "TextEditView.h"
#import "UIView+Extension.h"

@interface TextEditView()<UITextViewDelegate>
{
    
}
@end

@implementation TextEditView
{
    UITextView *textView ;
    
    UIButton *cancelBtn ;
    UIButton *comfirmBtn;
}

- (id)init
{
    self = [super initWithFrame:[[UIScreen mainScreen]bounds]];
    
    if(self){
        
        self.backgroundColor = [UIColor clearColor];
        
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *effectview = [[UIVisualEffectView alloc] initWithEffect:effect];
        effectview.frame = self.bounds;
        [self insertSubview:effectview atIndex:0];
        
        cancelBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 5, 60, 44)];
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:cancelBtn];
        
        comfirmBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.width - 60, 5, 60, 44)];
        [comfirmBtn setTitle:@"确定" forState:UIControlStateNormal];
        [comfirmBtn addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:comfirmBtn];
        
        textView = [[UITextView alloc]initWithFrame:CGRectMake(0, 44, self.width, self.height - 44)];
        textView.textColor = self.textColor;
        textView.font = self.textFont;
        textView.returnKeyType = UIReturnKeyNext ;
        textView.textAlignment = NSTextAlignmentLeft;
        textView.delegate = self ;
        textView.backgroundColor = [UIColor clearColor];
        textView.text = self.text;
        [textView becomeFirstResponder];
        [self addSubview:textView];
    }
    
    return self ;
}

- (void)setText:(NSString *)text
{
    _text = text ;
    
    textView.text = text ;
}

- (void)setTextFont:(UIFont *)textFont
{
    _textFont = textFont;
    
    textView.font = textFont;
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    
    textView.textColor = textColor;
}

- (void)buttonClick:(id)sender
{
    if(!textView.text.length){
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:@"请输入内容" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    [textView resignFirstResponder];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(textEditCompleteWithText:)]){
        [self.delegate textEditCompleteWithText:textView.text];
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        self.y = self.height ;
    }completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
}

#pragma mark - TextView Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
    
    return YES;
}

@end
