//
//  KKPuzzImageSelectController.h
//  
//
//  Created by finger on 17/2/16.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol startPuzzleImageDelegate <NSObject>

- (void)startPuzzleWithImageAssets:(NSArray *)assetArray;

@end

@interface KKPuzzImageSelectController : UIViewController

@property(nonatomic,weak)id<startPuzzleImageDelegate>delegate ;

@end
