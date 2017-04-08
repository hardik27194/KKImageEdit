//
//  KKEffectBase.h
//
//  Created by finger on 2015/10/23.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIImage+Extension.h"

@protocol KKEffectDelegate;

@interface KKEffectBase : NSObject
{
    
}

@property (nonatomic, weak) id<KKEffectDelegate> delegate;

- (UIImage*)applyEffect:(UIImage*)image;

- (id)initWithSuperView:(UIView*)superview;
- (void)cleanup;

@end

@protocol KKEffectDelegate <NSObject>
@required
- (void)effectParameterDidChange:(KKEffectBase*)effect;
@end
