//
//  KKImageFilterTool.h
//  
//
//  Created by finger on 17/2/13.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface KKImageFilterTool:NSObject

@property(nonatomic)NSString *curtFilterName ;

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image applyBlock:(void (^)(UIImage *))applyBlock;
- (void)cleanup;

- (UIImage*)filteredImage:(UIImage*)image withFilterName:(NSString*)filterName;

@end
