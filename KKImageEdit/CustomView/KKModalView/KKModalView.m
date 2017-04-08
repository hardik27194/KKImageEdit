//
//  KKModalView.m
//  
//
//  Created by finger on 17/2/16.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "KKModalView.h"
#import "UIView+Extension.h"

@implementation KKModalView
{
    UIButton *_bgView;
    UIView *_centerView;
}

- (instancetype)init
{
    self = [super init];
    if(self){
        [self bulidView];
    }
    return self ;
}

- (void)bulidView
{
    self.frame = [[UIScreen mainScreen]bounds];
    
    _bgView = [UIButton buttonWithType:UIButtonTypeCustom];
    _bgView.frame = self.bounds ;
    _bgView.backgroundColor = [UIColor clearColor];
    [_bgView addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_bgView];
    
    _centerView = [[UIView alloc]init];
    [self addSubview:_centerView];
}

- (void)startAnimateWithView:(UIView *)view
{
    _centerView.frame = CGRectMake((self.width - view.width ) / 2, (self.height - view.height) / 2, view.width, view.height) ;
    _centerView.layer.cornerRadius = view.layer.cornerRadius ;
    view.frame = _centerView.bounds ;
    [_centerView addSubview:view];
    
    [[[[UIApplication sharedApplication]delegate] window] addSubview:self];
    
    _centerView.maskView.alpha = 0;
    [UIView animateWithDuration:0.2 animations:^{
        _centerView.maskView.alpha = 1;
    }];
    
    _centerView.alpha = 0;
    _centerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4, 0.4);
    [UIView animateWithDuration:0.2 animations:^{
        _centerView.alpha = 1;
        _centerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _centerView.alpha = 1;
            _centerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
        } completion:^(BOOL finished2) {}];
    }];
}

- (void)startAnimateWithTimeOut:(NSTimeInterval)timeout
{
    [[[[UIApplication sharedApplication]delegate] window] addSubview:self];
    
    _centerView.maskView.alpha = 0;
    [UIView animateWithDuration:0.2 animations:^{
        _centerView.maskView.alpha = 1;
    }];
    
    _centerView.alpha = 0;
    _centerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4, 0.4);
    [UIView animateWithDuration:0.2 animations:^{
        _centerView.alpha = 1;
        _centerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _centerView.alpha = 1;
            _centerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
        } completion:^(BOOL finished2) {}];
    }];
    
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:timeout];
}

- (void)dismiss
{
    [UIView animateWithDuration:0.2 animations:^{
        _centerView.maskView.alpha = 0;
    }];
    
    [UIView animateWithDuration:0.2 animations:^{
        _centerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _centerView.alpha = 0;
            _centerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4, 0.4);
        } completion:^(BOOL finished2){
            [self removeFromSuperview];
        }];
    }];
}

@end
