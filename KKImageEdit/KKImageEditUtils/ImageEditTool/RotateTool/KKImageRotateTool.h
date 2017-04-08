//
//  KKImageRotateTool.h
//
//  Created by finger on 17/2/14.
//  Copyright © 2017年 fingerfinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger , KKRoteImageType){
    KKRoteTypeRoundRotate,
    KKRoteTypeFlipHorizonta,
    KKRoteTypeFlipVertical
};

@interface KKImageRotateTool : NSObject

@property(nonatomic)NSArray *rotateTypeArray;

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image;

- (void)cleanup;

- (UIImage*)buildImage:(UIImage*)image;

@end
