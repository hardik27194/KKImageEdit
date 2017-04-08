//
//  KKImageCollectionCellView.h
//  finger IOS AirMore
//
//  Created by finger on 15/3/16.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KKImageCollectionCellViewDelegate <NSObject>
- (void)selectedImage:(bool)selected indexPath:(NSIndexPath*)indexPath block:(void(^)(NSInteger selectCount))handler;
@end

@interface KKImageCollectionCellView : UICollectionViewCell

@property(nonatomic,weak)id<KKImageCollectionCellViewDelegate>delegate;

@property(nonatomic)NSIndexPath *indexPath;

@property(nonatomic,retain)UIImage *image;
@property(nonatomic,assign)BOOL seletedImage ;

+ (KKImageCollectionCellView *)loadViewFromNibName:(NSString *)nibName;

- (void)setSeletedMode:(BOOL)bSelMode;

@end
