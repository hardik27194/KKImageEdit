//
//  EffectTool.m
//
//  Created by finger on 2015/10/23.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "KKImageEffectTool.h"
#import "UIView+Extension.h"
#import "UIImage+Extension.h"
#import "KKImageEditToolItem.h"

typedef void(^applyBlock)(UIImage *image);

@interface KKImageEffectTool()<KKEffectDelegate,KKImageEditToolItemDelegate>
{
    UIView *superView ;
    UIScrollView *menuScrollView;
    
    UIImage *originalImage;
    UIImage *thumbnailImage;
    
    CGRect imageViewFrame ;
    
    applyBlock _applyBlock ;
    
    KKImageEditToolItem *lastItem ;
}

@property(nonatomic)NSArray *effectArray ;

@end

@implementation KKImageEffectTool
{
    KKEffectBase *effectBase ;
}

- (instancetype)init
{
    self = [super init];
    
    if(self){
        
        self.effectArray = @[
                             @{@"name":@"KKEffectBase",@"title":@"无"},
                             @{@"name":@"KKBloomEffect",@"title":@"Bloom"},
                             @{@"name":@"KKGloomEffect",@"title":@"阴影"},
                             @{@"name":@"KKPosterizeEffect",@"title":@"色调分离"},
                             @{@"name":@"KKPixellateEffect",@"title":@"像素化"},
                             @{@"name":@"KKSpotEffect",@"title":@"聚光"},
                             @{@"name":@"KKHueEffect",@"title":@"色相"},
                             @{@"name":@"KKHighlightShadowEffect",@"title":@"高亮"},
                             @{@"name":@"KKVignetteEffect",@"title":@"晕影"},
                             ];
        
    }
    
    return self ;
}

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView image:(UIImage *)image applyBlock:(void (^)(UIImage *))applyBlock
{
    superView = view ;
    imageViewFrame = frame ;
    originalImage = image ;
    
    _applyBlock = [applyBlock copy];
    
    CGFloat imageW = originalImage.size.width;
    CGFloat imageH = originalImage.size.height;
    CGFloat imageViewW = imageViewFrame.size.width ;
    CGFloat imageViewH = imageViewFrame.size.height ;
    CGFloat rw = imageViewW / imageW ;
    CGFloat rh = imageViewH / imageH ;
    CGFloat r = MIN(rw,rh);
    CGSize size = CGSizeMake(imageW * r, imageH * r);
    thumbnailImage = [originalImage getThumbnailWithScaleSize:size];
    
    CGFloat x = 0;
    CGFloat W = 50;
    CGFloat H = menuView.height;
    CGFloat padding = 5 ;
    
    UIImage *tempImage = [image scaleWithFactor:0.1 quality:0.1];
    
    menuScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, menuView.height, menuView.width, menuView.height)];
    menuScrollView.backgroundColor = [UIColor blackColor];
    [menuView addSubview:menuScrollView];
    
    for(NSDictionary *effectInfo in self.effectArray){
        
        KKImageEditToolItem *item = [[KKImageEditToolItem alloc]init];
        item.itemTitle = [effectInfo objectForKey:@"title"];
        item.delegate = self ;
        item.editType = KKImageEditTypeEffect ;
        item.editInfo = effectInfo ;
        item.frame = CGRectMake(x, 0, W, H);
        
        if([[effectInfo objectForKey:@"name"]isEqualToString:@"KKEffectBase"]){
            lastItem = item ;
            lastItem.selected = YES ;
        }
        
        [menuScrollView addSubview:item];
        
        x += (W + padding);
    }
    
    menuScrollView.contentSize = CGSizeMake(MAX(x, menuScrollView.frame.size.width+1), 0);
    
    [UIView animateWithDuration:0.3 animations:^{
        [menuScrollView setFrame:menuView.bounds];
    }];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        for(UIView *view in menuScrollView.subviews){
            
            if([view isKindOfClass:[KKImageEditToolItem class]]){
                
                KKImageEditToolItem *item = (KKImageEditToolItem *)view ;
                
                NSDictionary *editInfo = [item editInfo];
                NSString *effectName = [editInfo objectForKey:@"name"];
                
                KKEffectBase *baseClass = [self getEffectWithEffectName:effectName];
                
                UIImage *effectImage = [baseClass applyEffect:tempImage];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [item setItemImage:effectImage];
                });
                
            }
        }
        
    });
}

- (void)cleanup
{
    [menuScrollView removeFromSuperview];
    
    [effectBase cleanup];
}

#pragma mark -- 根据效果名称初始化效果类

- (KKEffectBase *)getEffectWithEffectName:(NSString *)effectName
{
    KKEffectBase *base = nil ;
    Class class = NSClassFromString(effectName);
    if(class){
        base = [[class alloc]init];
    }
    
    return base ;
}

- (void)setEffectWithName:(NSString *)effectName superView:(UIView*)superview
{
    [effectBase cleanup];
    [effectBase setDelegate:nil];
    
    Class class = NSClassFromString(effectName);
    if(class){
        effectBase = [[class alloc]initWithSuperView:superview];
    }
    
    [effectBase setDelegate:self];
}

- (UIImage*)applyEffect:(UIImage*)image
{
    return [effectBase applyEffect:image];
}

#pragma mark -- KKEffectDelegate

- (void)effectParameterDidChange:(KKEffectBase *)effect
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        UIImage *rstImage = [self applyEffect:thumbnailImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(_applyBlock){
                _applyBlock(rstImage);
            }
        });
        
    });
}

#pragma mark -- KKImageEditToolItemDelegate

- (void)imageEditItem:(KKImageEditToolItem *)item clickItemWithType:(KKImageEditType)editType editInfo:(NSDictionary *)editInfo
{
    if(item.selected){
        return ;
    }
    
    lastItem.selected = NO ;
    lastItem = item ;
    lastItem.selected = YES ;
    
    NSString *effectName = [editInfo objectForKey:@"name"];
    
    [self setEffectWithName:effectName superView:superView];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        UIImage *rstImage = [self applyEffect:thumbnailImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(_applyBlock){
                _applyBlock(rstImage);
            }
        });
        
    });
    
}

#pragma mark -- 生成结果图

- (void)effectImage:(UIImage*)image block:(void (^)(UIImage *))block
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        UIImage *effectImage = [self applyEffect:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(block){
                block(effectImage);
            }
        });
    });
}

@end
