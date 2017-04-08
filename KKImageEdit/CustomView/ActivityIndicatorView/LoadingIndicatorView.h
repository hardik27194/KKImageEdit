//
//  LoadingIndicatorView.h
//
//  Created by finger on 16/7/8.
//  Copyright © 2016年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoadingIndicatorView : UIView

- (void)startAnimateWithTimeOut:(NSTimeInterval)timeout;
- (void)dismiss;
- (void)resetViewWithOrientation:(NSInteger)toOrientation;

@end
