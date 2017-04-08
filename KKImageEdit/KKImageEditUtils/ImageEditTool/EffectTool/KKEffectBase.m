//
//  KKEffectBase.m
//
//  Created by finger on 2015/10/23.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "KKEffectBase.h"

@implementation KKEffectBase

- (id)initWithSuperView:(UIView*)superview
{
    self = [super init];
    
    if(self){
        
    }
    
    return self ;
}

- (UIImage*)applyEffect:(UIImage*)image
{
    return image;
}

- (void)cleanup
{
    
}

@end
