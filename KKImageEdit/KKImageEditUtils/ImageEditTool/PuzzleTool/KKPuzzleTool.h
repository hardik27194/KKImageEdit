//
//  PuzzleTool.h
//
//  Created by finger on 2014/06/20.
//  Copyright (c) 2014年 finger. All rights reserved.
//

#import <UIKit/UIkit.h>

@interface KKPuzzleTool : NSObject
{
}

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView puzzleImageArray:(NSArray *)array;
- (void)cleanup;

- (void)genPuzzleImageWithBlock:(void (^)(UIImage *))completionBlock;

@end
