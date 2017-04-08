//
//  ClippingTool.h
//
//  Created by finger on 2015/10/18.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KKImageClipTool : NSObject
{
    
}

- (void)setupWithSuperView:(UIView *)imageView imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image;
- (void)cleanup;

- (void)clipImageWithBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock;

@end
