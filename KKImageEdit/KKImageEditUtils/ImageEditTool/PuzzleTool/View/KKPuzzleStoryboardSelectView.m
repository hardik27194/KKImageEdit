//
//  puzzleStoryboardSelectView.m
//
//  Created by finger on 1/22/16.
//  Copyright (c) 2016年 finger. All rights reserved.

#import "KKPuzzleStoryboardSelectView.h"

@interface KKPuzzleStoryboardSelectView()
{
    NSInteger _picCount;
    NSMutableArray *_imageNameArray;
    
    UIScrollView  *_storyboardView;
}

@end

@implementation KKPuzzleStoryboardSelectView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        
        _storyboardView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 50)];
        _storyboardView.showsHorizontalScrollIndicator = NO ;
        _storyboardView.showsVerticalScrollIndicator = NO ;
        [self addSubview:_storyboardView];
        
    }
    
    return self;
}

- (void)setPicCount:(NSInteger)picCount
{
    if(_picCount == picCount){
        return ;
    }
    _picCount = picCount ;
    
    CGFloat width = 116/2.0f;
    CGFloat height = 100/2.0f;
    
    [_imageNameArray removeAllObjects];
    
    switch (_picCount)
    {
        case 2:
        {
            _imageNameArray = [NSMutableArray arrayWithObjects:@"makecards_puzzle_storyboard1_icon",
                               @"makecards_puzzle_storyboard2_icon",
                               @"makecards_puzzle_storyboard3_icon",
                               @"makecards_puzzle_storyboard4_icon",
                               @"makecards_puzzle_storyboard5_icon",
                               @"makecards_puzzle_storyboard6_icon",nil];
            break;
        }
        case 3:
        {
            _imageNameArray = [NSMutableArray arrayWithObjects:@"makecards_puzzle3_storyboard1_icon",
                               @"makecards_puzzle3_storyboard2_icon",
                               @"makecards_puzzle3_storyboard3_icon",
                               @"makecards_puzzle3_storyboard4_icon",
                               @"makecards_puzzle3_storyboard5_icon",
                               @"makecards_puzzle3_storyboard6_icon",nil];
            break;
        }
        case 4:
        {
            _imageNameArray = [NSMutableArray arrayWithObjects:@"makecards_puzzle4_storyboard1_icon",
                               @"makecards_puzzle4_storyboard2_icon",
                               @"makecards_puzzle4_storyboard3_icon",
                               @"makecards_puzzle4_storyboard4_icon",
                               @"makecards_puzzle4_storyboard5_icon",
                               @"makecards_puzzle4_storyboard6_icon",nil];
            break;
        }
        case 5:
        {
            _imageNameArray = [NSMutableArray arrayWithObjects:@"makecards_puzzle5_storyboard1_icon",
                               @"makecards_puzzle5_storyboard2_icon",
                               @"makecards_puzzle5_storyboard3_icon",
                               @"makecards_puzzle5_storyboard4_icon",
                               @"makecards_puzzle5_storyboard5_icon",
                               @"makecards_puzzle5_storyboard6_icon",nil];
            break;
        }
        default:break;
    }
    
    for(UIView *view in _storyboardView.subviews){
        if([view isKindOfClass:[UIButton class]]){
            [view removeFromSuperview];
        }
    }
    
    for (int i = 0; i < [_imageNameArray count]; i++) {
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(i*width+(width-37)/2.0f, 2.5f, 37, 45)];
        [button setImage:[UIImage imageNamed:[_imageNameArray objectAtIndex:i]] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(storyboardAction:) forControlEvents:UIControlEventTouchUpInside];
        [button setTag:i+1];
        [_storyboardView addSubview:button];
        
    }
    
    self.selectIndex = 1 ;
    
    [_storyboardView setContentSize:CGSizeMake([_imageNameArray count]*width, height)];
}

- (void)setSelectIndex:(NSInteger)selectIndex
{
    _selectIndex = selectIndex ;
    
    for(UIView *view in _storyboardView.subviews){
        if([view isKindOfClass:[UIButton class]]){
            UIButton *btn = (UIButton *)view ;
            NSInteger tag = btn.tag ;
            if(tag == selectIndex){
                btn.backgroundColor = [UIColor redColor];
            }else{
                btn.backgroundColor = [UIColor clearColor];
            }
        }
    }
}

#pragma mark -- 拼图样式的选择

- (void)storyboardAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    if (self.selectIndex == button.tag) {
        return;
    }
    self.selectIndex = button.tag;
    
    if (_delegateSelect && [_delegateSelect respondsToSelector:@selector(didSelectedStoryboardPicCount:styleIndex:)]) {
        [_delegateSelect didSelectedStoryboardPicCount:_picCount styleIndex:self.selectIndex];
    }
}

@end
