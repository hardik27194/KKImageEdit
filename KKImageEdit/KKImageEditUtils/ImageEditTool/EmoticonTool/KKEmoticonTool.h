//
//  EmoticonTool.h
//
//  Created by Mokhlas Hussein on 01/02/14.
//  Copyright (c) 2014 iMokhles. All rights reserved.
//  ImageTool Author finger.
//

#import <UIKit/UIKit.h>

@interface KKEmoticonTool :NSObject
{
    
}

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image;
- (void)cleanup;

- (void)genEmotionImageWithBlock:(void (^)(UIImage *))completionBlock;

@end
