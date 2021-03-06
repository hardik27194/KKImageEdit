//
//  PuzzleTool.m
//
//  Created by finger on 2014/06/20.
//  Copyright (c) 2014年 finger. All rights reserved.
//

#import "KKPuzzleTool.h"
#import "KKPuzzleEditImageView.h"
#import "KKPuzzleStoryboardSelectView.h"
#import "UIView+Extension.h"
#import "LoadingIndicatorView.h"

@import Photos ;

@interface KKPuzzleTool()<KKPuzzleStoryboardSelectViewDelegate>
{
    UIScrollView *_puzzleContentView;
    KKPuzzleStoryboardSelectView *_storyboardSelectView;
    
    LoadingIndicatorView *indicatorView;
}

@property(nonatomic)NSArray *assetArray;

@end

@implementation KKPuzzleTool

- (void)setupWithSuperView:(UIView *)view imageViewFrame:(CGRect)frame menuView:(UIView *)menuView puzzleImageArray:(NSArray *)array
{
    self.assetArray = array ;
    
    _puzzleContentView = [[UIScrollView alloc] initWithFrame:view.bounds];
    [_puzzleContentView setBackgroundColor:[UIColor blackColor]];
    [view addSubview:_puzzleContentView];
    
    _storyboardSelectView = [[KKPuzzleStoryboardSelectView alloc]initWithFrame:menuView.bounds];
    _storyboardSelectView.delegateSelect = self ;
    _storyboardSelectView.picCount = self.assetArray.count;
    _storyboardSelectView.selectIndex = 1 ;
    _storyboardSelectView.backgroundColor = [UIColor blackColor];
    [menuView addSubview:_storyboardSelectView];
    
    _storyboardSelectView.transform = CGAffineTransformMakeTranslation(0, _storyboardSelectView.height);
    [UIView animateWithDuration:0.3 animations:^{
        _storyboardSelectView.transform = CGAffineTransformIdentity;
    }];
    
    [self resetStoryboardByStyle:1 imageCount:_assetArray.count];
}

- (void)cleanup
{
    [_storyboardSelectView removeFromSuperview];
    [_puzzleContentView removeFromSuperview];
}

#pragma mark -- 生成最终的图片

- (void)genPuzzleImageWithBlock:(void (^)(UIImage *))completionBlock
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        UIImage *image = [self bulidPuzzleImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image);
        });
        
    });
}

- (UIImage *)bulidPuzzleImage
{
    UIImage* image = nil;
    
    UIGraphicsBeginImageContextWithOptions(_puzzleContentView.contentSize, NO, 2.0);
    {
        CGPoint savedContentOffset = _puzzleContentView.contentOffset;
        CGRect savedFrame = _puzzleContentView.frame;
        _puzzleContentView.contentOffset = CGPointZero;
        _puzzleContentView.frame = CGRectMake(0, 0, _puzzleContentView.contentSize.width, _puzzleContentView.contentSize.height);
        
        [_puzzleContentView.layer renderInContext: UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        _puzzleContentView.contentOffset = savedContentOffset;
        _puzzleContentView.frame = savedFrame;
    }
    UIGraphicsEndImageContext();
    
    if (image != nil) {
        return image;
    }
    
    return nil;
}

#pragma mark -- 设置拼图界面

- (void)resetStoryboardByStyle:(NSInteger)index imageCount:(NSInteger)count
{
    [self showIndicatorView];
    
    for(UIView *view in _puzzleContentView.subviews){
        if([view isKindOfClass:[KKPuzzleEditImageView class]]){
            [view removeFromSuperview];
        }
    }
    _puzzleContentView.contentOffset = CGPointZero;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSString *picCountIndex = @"";
        
        NSString *styleIndex = @"";
        
        switch (count)
        {
            case 2:
                picCountIndex = @"two";
                break;
            case 3:
                picCountIndex = @"three";
                break;
            case 4:
                picCountIndex = @"four";
                break;
            case 5:
                picCountIndex = @"five";
                break;
            default:break;
        }
        
        switch (index)
        {
            case 1:
                styleIndex = @"1";
                break;
            case 2:
                styleIndex = @"2";
                break;
            case 3:
                styleIndex = @"3";
                break;
            case 4:
                styleIndex = @"4";
                break;
            case 5:
                styleIndex = @"5";
                break;
            case 6:
                styleIndex = @"6";
                break;
            default:break;
        }
        
        NSString *sbSourcePath = [[[NSBundle mainBundle]bundlePath]stringByAppendingPathComponent:@"StoryboardPlist"];
        sbSourcePath = [sbSourcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"number_%@_style_%@.plist",picCountIndex,styleIndex]];
        
        NSDictionary *styleDict = [NSDictionary dictionaryWithContentsOfFile:sbSourcePath];
        
        if (styleDict) {
            
            CGSize superSize = CGSizeFromString([[styleDict objectForKey:@"SuperViewInfo"] objectForKey:@"size"]);
            superSize = [self sizeScaleWithSize:superSize scale:2.0f];
            
            NSArray *subViewArray = [styleDict objectForKey:@"SubViewArray"];
            
            for(int j = 0; j < [subViewArray count]; j++){
                
                CGRect rect = CGRectZero;
                
                UIBezierPath *path = nil;
                
                NSDictionary *subDict = [subViewArray objectAtIndex:j];
                
                NSArray *pointArray = [subDict objectForKey:@"pointArray"];
                
                rect = [self rectWithArray:pointArray andSuperSize:superSize];
                
                if (pointArray) {
                    
                    rect = [self rectWithArray:pointArray andSuperSize:superSize];
                    
                    path = [UIBezierPath bezierPath];
                    
                    if (pointArray.count > 2) {
                        
                        for(int i = 0; i < [pointArray count]; i++){
                            
                            NSString *pointString = [pointArray objectAtIndex:i];
                            
                            if (pointString) {
                                
                                CGPoint point = CGPointFromString(pointString);
                                point = [self pointScaleWithPoint:point scale:2.0f];
                                point.x = (point.x)*_puzzleContentView.frame.size.width/superSize.width -rect.origin.x;
                                point.y = (point.y)*_puzzleContentView.frame.size.height/superSize.height -rect.origin.y;
                                if (i == 0) {
                                    [path moveToPoint:point];
                                }else{
                                    [path addLineToPoint:point];
                                }
                                
                            }
                        }
                        
                    }else{
                        
                        //当点的左边不能形成一个面的时候  至少三个点的时候 就是一个正规的矩形
                        //点的坐标就是rect的四个角
                        [path moveToPoint:CGPointMake(0, 0)];
                        [path addLineToPoint:CGPointMake(rect.size.width, 0)];
                        [path addLineToPoint:CGPointMake(rect.size.width, rect.size.height)];
                        [path addLineToPoint:CGPointMake(0, rect.size.height)];
                        
                    }
                    
                    [path closePath];
                    
                }
                
                __block UIImage *image = nil;
                
                if(_assetArray.count){
                    
                    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                    options.networkAccessAllowed = YES;
                    options.synchronous = YES ;
                    
                    [[PHImageManager defaultManager] requestImageForAsset:[_assetArray objectAtIndex:j] targetSize:superSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *result, NSDictionary *info)
                     {
                         bool downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                         if (result && downloadFinined) {
                             image = result ;
                         }
                         
                     }];
                    
                }
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    KKPuzzleEditImageView *imageView = [[KKPuzzleEditImageView alloc] initWithFrame:rect];
                    imageView.clipsToBounds = YES;
                    imageView.backgroundColor = [UIColor grayColor];
                    imageView.tag = j;
                    imageView.realCellArea = path;
                    [imageView setImageViewData:image];
                    [_puzzleContentView addSubview:imageView];
                    
                });
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            _puzzleContentView.contentSize = _puzzleContentView.frame.size;
            
            [self hideIndicatorView];
            
        });
        
    });
}

#pragma mark -- 根据缩放比例调整矩形大小、点的位置

- (CGSize)sizeScaleWithSize:(CGSize)size scale:(CGFloat)scale
{
    if (scale<=0) {
        scale = 1.0f;
    }
    CGSize retSize = CGSizeZero;
    retSize.width = size.width/scale;
    retSize.height = size.height/scale;
    
    return  retSize;
}

- (CGPoint)pointScaleWithPoint:(CGPoint)point scale:(CGFloat)scale
{
    if (scale<=0) {
        scale = 1.0f;
    }
    CGPoint retPointt = CGPointZero;
    retPointt.x = point.x/scale;
    retPointt.y = point.y/scale;
    
    return  retPointt;
}

- (CGRect)rectScaleWithRect:(CGRect)rect scale:(CGFloat)scale
{
    if (scale<=0) {
        scale = 1.0f;
    }
    CGRect retRect = CGRectZero;
    retRect.origin.x = rect.origin.x/scale;
    retRect.origin.y = rect.origin.y/scale;
    retRect.size.width = rect.size.width/scale;
    retRect.size.height = rect.size.height/scale;
    return  retRect;
}

#pragma mark -- 根据点来确定矩形

- (CGRect)rectWithArray:(NSArray *)array andSuperSize:(CGSize)superSize
{
    CGRect rect = CGRectZero;
    CGFloat minX = INT_MAX;
    CGFloat maxX = 0;
    CGFloat minY = INT_MAX;
    CGFloat maxY = 0;
    for (int i = 0; i < [array count]; i++) {
        NSString *pointString = [array objectAtIndex:i];
        CGPoint point = CGPointFromString(pointString);
        if (point.x <= minX) {
            minX = point.x;
        }
        if (point.x >= maxX) {
            maxX = point.x;
        }
        if (point.y <= minY) {
            minY = point.y;
        }
        if (point.y >= maxY) {
            maxY = point.y;
        }
        rect = CGRectMake(minX, minY, maxX - minX, maxY - minY);
    }
    rect = [self rectScaleWithRect:rect scale:2.0f];
    rect.origin.x = rect.origin.x * _puzzleContentView.frame.size.width/superSize.width;
    rect.origin.y = rect.origin.y * _puzzleContentView.frame.size.height/superSize.height;
    rect.size.width = rect.size.width * _puzzleContentView.frame.size.width/superSize.width;
    rect.size.height = rect.size.height * _puzzleContentView.frame.size.height/superSize.height;
    
    return rect;
}

#pragma mark -- KKPuzzleStoryboardSelectViewDelegate

- (void)didSelectedStoryboardPicCount:(NSInteger)picCount styleIndex:(NSInteger)styleIndex
{
    [self resetStoryboardByStyle:styleIndex imageCount:picCount];
}

#pragma mark -- 显示进度

- (void)showIndicatorView
{
    [self hideIndicatorView];
    
    indicatorView = [[LoadingIndicatorView alloc]init];
    [indicatorView startAnimateWithTimeOut:8.0];
}

- (void)hideIndicatorView
{
    if(indicatorView){
        [indicatorView removeFromSuperview];
        indicatorView = nil ;
    }
}

@end
