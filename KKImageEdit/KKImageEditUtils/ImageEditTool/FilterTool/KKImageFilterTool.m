//
//  KKImageFilterTool.m
//  
//
//  Created by finger on 17/2/13.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "KKImageFilterTool.h"
#import "KKImageEditToolItem.h"
#import "UIView+Extension.h"
#import "UIImage+Extension.h"

typedef void(^applyBlock)(UIImage *image);

@interface KKImageFilterTool()<KKImageEditToolItemDelegate>

@property(nonatomic)NSArray *filterTypeArray;

@end

@implementation KKImageFilterTool
{
    UIScrollView *menuScrollView ;
    
    UIImage *originalImage ;
    UIImage *thumbnailImage;
    
    applyBlock _applyBlock ;
    
    KKImageEditToolItem *lastItem ;
}

- (instancetype)init
{
    self = [super init];
    
    if(self){
        
        self.filterTypeArray = @[
                                 @{@"name":@"DefaultEmptyFilter",@"title":@"无"},
                                 @{@"name":@"CISRGBToneCurveToLinear",@"title":@"线性"},
                                 @{@"name":@"CIPhotoEffectInstant",@"title":@"怀旧"},
                                 @{@"name":@"CIPhotoEffectProcess",@"title":@"冲印"},
                                 @{@"name":@"CIPhotoEffectTransfer",@"title":@"岁月"},
                                 @{@"name":@"CISepiaTone",@"title":@"棕镜"},
                                 @{@"name":@"CIPhotoEffectChrome",@"title":@"铬黄"},
                                 @{@"name":@"CIPhotoEffectFade",@"title":@"褪色"},
                                 @{@"name":@"CILinearToSRGBToneCurve",@"title":@"曲线"},
                                 @{@"name":@"CIPhotoEffectTonal",@"title":@"色调"},
                                 @{@"name":@"CIPhotoEffectNoir",@"title":@"黑白"},
                                 @{@"name":@"CIPhotoEffectMono",@"title":@"单色"},
                                 @{@"name":@"CIColorInvert",@"title":@"反转"},
                                 ];
        
    }
    
    return self ;
}

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)imageViewFrame menuView:(UIView *)menuView image:(UIImage *)image applyBlock:(void (^)(UIImage *))applyBlock
{
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
    
    for(NSDictionary *filterInfo in self.filterTypeArray){
        
        KKImageEditToolItem *item = [[KKImageEditToolItem alloc]init];
        item.itemTitle = [filterInfo objectForKey:@"title"];
        item.delegate = self ;
        item.editType = KKImageEditTypeFilter ;
        item.editInfo = filterInfo ;
        item.frame = CGRectMake(x, 0, W, H);
        
        if([[filterInfo objectForKey:@"name"]isEqualToString:@"DefaultEmptyFilter"]){
            lastItem = item ;
            lastItem.selected = YES ;
            _curtFilterName = @"DefaultEmptyFilter";
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
                NSString *filterName = [editInfo objectForKey:@"name"];
                UIImage *filterImage = [self filteredImage:tempImage withFilterName:filterName];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [item setItemImage:filterImage];
                });
                
            }
        }
        
    });
}

- (void)cleanup
{
    [menuScrollView removeFromSuperview];
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
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        _curtFilterName = [editInfo objectForKey:@"name"];
        UIImage *rstImage = [self filteredImage:thumbnailImage withFilterName:_curtFilterName];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(_applyBlock){
                _applyBlock(rstImage);
            }
        });
        
    });
}

#pragma mark -- filter image

- (UIImage*)filteredImage:(UIImage*)image withFilterName:(NSString*)filterName
{
    if([filterName isEqualToString:@"DefaultEmptyFilter"]){
        _curtFilterName = filterName ;
        return image;
    }
    
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:filterName keysAndValues:kCIInputImageKey, ciImage, nil];
    
    [filter setDefaults];
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

@end
