//
//  puzzleStoryboardSelectView.h
//
//  Created by finger on 1/22/16.
//  Copyright (c) 2016年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KKPuzzleStoryboardSelectViewDelegate;

@interface KKPuzzleStoryboardSelectView : UIView
{
    
}

@property (nonatomic, assign) id<KKPuzzleStoryboardSelectViewDelegate> delegateSelect;
@property (nonatomic, assign) NSInteger picCount;
@property (nonatomic, assign) NSInteger selectIndex;

@end

@protocol KKPuzzleStoryboardSelectViewDelegate <NSObject>
- (void)didSelectedStoryboardPicCount:(NSInteger)picCount styleIndex:(NSInteger)styleIndex;
@end
