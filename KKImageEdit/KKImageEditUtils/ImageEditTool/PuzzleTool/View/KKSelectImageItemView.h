//
//  KKSelectImageItemView.h
//  
//
//  Created by finger on 17/2/17.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KKSelectImageItemViewDelegate;

@interface KKSelectImageItemView : UIView

@property(nonatomic,weak)id<KKSelectImageItemViewDelegate>delegate;
@property(nonatomic,assign)NSInteger imageIndex ;
@property(nonatomic)UIImage *image ;

@end

@protocol KKSelectImageItemViewDelegate <NSObject>

- (void)removeImageWithIndex:(NSInteger)index;

@end
