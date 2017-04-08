//
//  puzzleEditImageView.h
//
//  Created by finger on 1/22/16.
//  Copyright (c) 2016年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KKPuzzleEditImageView : UIScrollView<UIScrollViewDelegate>
{
    
}

@property (nonatomic, retain) UIBezierPath *realCellArea;

- (void)setImageViewData:(UIImage *)imageData;

@end
