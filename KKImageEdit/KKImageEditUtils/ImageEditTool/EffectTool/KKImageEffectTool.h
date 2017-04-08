//
//  KKImageEffectTool.h
//
//  Created by finger on 2015/10/23.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "KKEffectBase.h"
#import "KKBloomEffect.h"
#import "KKGloomEffect.h"
#import "KKHighlightShadowEffect.h"
#import "KKHueEffect.h"
#import "KKPixellateEffect.h"
#import "KKPosterizeEffect.h"
#import "KKSpotEffect.h"
#import "KKVignetteEffect.h"

@interface KKImageEffectTool : NSObject
{
    
}

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image applyBlock:(void (^)(UIImage *))applyBlock;

- (void)cleanup;

- (void)effectImage:(UIImage*)image block:(void (^)(UIImage *))block;

@end
