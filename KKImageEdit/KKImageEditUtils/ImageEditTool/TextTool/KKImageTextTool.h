//
//  KKImageTextTool.h
//  
//
//  Created by finger on 17/2/18.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface KKImageTextTool : NSObject

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image;

- (void)cleanup;

- (void)genEditTextImageWithBlock:(void (^)(UIImage *))completionBlock;

@end
