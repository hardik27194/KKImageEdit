//
//  BlurTool.h
//
//  Created by finger on 2015/10/19.
//  Copyright (c) 2015年 finger All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KKBlurTool : NSObject
{
    
}

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image;
- (void)cleanup;

- (void)genBlurImageWithBlock:(void(^)(UIImage *image))completionBlock;

@end
