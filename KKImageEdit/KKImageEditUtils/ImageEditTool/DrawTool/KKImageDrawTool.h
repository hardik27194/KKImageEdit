//
//  DrawTool.h
//
//  Created by finger on 2014/06/20.
//  Copyright (c) 2014年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KKImageDrawTool : NSObject
{
    
}

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image;
- (void)cleanup;
- (void)genDrawImageWithBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock;

@end
