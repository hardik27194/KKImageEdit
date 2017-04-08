//
//  KKImageCollectionCellView.m
//
//  Created by finger on 15/3/16.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "KKImageCollectionCellView.h"

@implementation KKImageCollectionCellView
{
    IBOutlet UIImageView *mImage;
    
    UIView *maskView;
    UIButton *mSeleteBtn;
}

@synthesize seletedImage ;

+ (KKImageCollectionCellView *)loadViewFromNibName:(NSString *)nibName
{
    UINib *nib = [UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]];
    
    if (nib != nil){
        
        NSArray *subViews = [nib instantiateWithOwner:self options:nil];
        if (subViews.count > 0){
            
            for (NSObject *obj in subViews){
                
                if ([obj isKindOfClass:[KKImageCollectionCellView class]]){
                    
                    KKImageCollectionCellView *cellView = (KKImageCollectionCellView *)obj;
                    [cellView _init];
                    
                    return cellView;
                    
                }
            }
        }
    }
    
    return nil;
}

- (void)_init
{
}

- (UIView *)tapMaskView
{
    if(!maskView){
        
        maskView = [[UIView alloc]initWithFrame:CGRectMake(self.frame.size.width * 1 / 3, self.frame.size.width * 1 / 3, self.frame.size.width * 2 / 3, self.frame.size.width * 2 / 3)];
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapImage:)];
        tapRecognizer.numberOfTapsRequired = 1 ;
        tapRecognizer.numberOfTouchesRequired = 1 ;
        
        [maskView addGestureRecognizer:tapRecognizer];
        
        [self addSubview:maskView];
    }
    
    return maskView ;
}

- (UIButton*)seleteBtn
{
    if(!mSeleteBtn){
        
        mSeleteBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.frame.size.width - 30, self.frame.size.height - 30, 25, 25)];
        [mSeleteBtn setImage:[UIImage imageNamed:@"checkbox-normal-grey"] forState:UIControlStateNormal];
        [mSeleteBtn setImage:[UIImage imageNamed:@"checkbox-selected"] forState:UIControlStateSelected];
        [mSeleteBtn setHidden:YES];
        [mSeleteBtn setUserInteractionEnabled:YES];
        [mSeleteBtn addTarget:self action:@selector(selectBtnClick) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:mSeleteBtn];
        
    }
    return mSeleteBtn ;
}

- (void)tapImage:(UIGestureRecognizer*)recognizer
{
    seletedImage = !seletedImage ;
    
    [self.seleteBtn setSelected:seletedImage];
    [self bringSubviewToFront:self.seleteBtn];
    
    if(_delegate && [_delegate respondsToSelector:@selector(selectedImage:indexPath:block:)]){
        [_delegate selectedImage:seletedImage indexPath:_indexPath block:nil];
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Initialization code
}

- (void)setImage:(UIImage *)image
{
    if(image == nil){
        image = [UIImage imageNamed:@"noPhoto"];
    }
    mImage.image = image;
}

- (UIImage *)image
{
    return mImage.image;
}

- (void)setSeletedImage:(BOOL)seleted
{
    seletedImage = seleted ;
    [self.seleteBtn setSelected:seletedImage];
    [self bringSubviewToFront:self.seleteBtn];
}

- (BOOL)seletedImage
{
    return seletedImage ;
}

- (void)setSeletedMode:(BOOL)bSelMode
{
    if(bSelMode){
        [self.seleteBtn setHidden:NO];
        [self bringSubviewToFront:self.seleteBtn];
        [self.tapMaskView setHidden:NO];
    }else{
        [self.seleteBtn setHidden:YES];
        [self.tapMaskView setHidden:YES];
    }
}

- (void)selectBtnClick
{
    seletedImage = !seletedImage ;
    [self.seleteBtn setSelected:seletedImage];
    [self bringSubviewToFront:self.seleteBtn];
    
    if(_delegate && [_delegate respondsToSelector:@selector(selectedImage:indexPath:block:)]){
        [_delegate selectedImage:seletedImage indexPath:_indexPath block:nil];
    }
}

- (void)dealloc
{

}

@end
