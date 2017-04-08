//
//  KKSelectImageItemView.m
//  
//
//  Created by finger on 17/2/17.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "KKSelectImageItemView.h"
#import "UIView+Extension.h"

@implementation KKSelectImageItemView
{
    UIButton *closeBtn ;
    UIImageView *imageView ;
}

- (id)init
{
    self = [super init];
    
    if(self){
        [self buildView];
    }
    
    return self ;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if(self){
        [self buildView];
    }
    
    return self ;
}

- (void)buildView
{
    closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(0, 5, 20, 20);
    [closeBtn setImage:[UIImage imageNamed:@"btn_delete"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeClicked) forControlEvents:UIControlEventTouchUpInside];
    
    imageView = [[UIImageView alloc]initWithFrame:CGRectMake(closeBtn.center.x, closeBtn.center.y, self.width - closeBtn.center.x, self.height - closeBtn.center.y - 5)];
    imageView.contentMode = UIViewContentModeScaleAspectFill ;
    imageView.clipsToBounds = YES ;
    
    [self addSubview:imageView];
    [self addSubview:closeBtn];
}

- (void)closeClicked
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(removeImageWithIndex:)]){
        [self .delegate removeImageWithIndex:self.imageIndex];
    }
}

#pragma mark -- @@property

- (void)setImage:(UIImage *)image
{
    _image = image ;
    imageView.image = image ;
}

@end
