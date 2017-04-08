//
//  KKModalView.h
//  
//
//  Created by finger on 17/2/16.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KKModalView : UIView

- (void)startAnimateWithView:(UIView *)view;
- (void)startAnimateWithTimeOut:(NSTimeInterval)timeout;
- (void)dismiss;

@end
