//
//  KKImageEditController.m
//  
//
//  Created by finger on 17/2/13.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "KKImageEditController.h"
#import "KKImageEditToolItem.h"
#import "UIImage+Extension.h"
#import "LoadingIndicatorView.h"
#import "KKImageEditTool.h"
#import "KKPuzzImageSelectController.h"
#import "UIView+Extension.h"
#import "KKPhotoManager.h"
#import "KKNavViewController.h"

#define HISTORY_EDIT_CURTINDEX @"curtShowIndex"
#define HISTORY_EDIT_IMAGEPATH @"historyImagePath"

@interface KKImageEditController ()<KKImageEditToolItemDelegate,UIScrollViewDelegate,startPuzzleImageDelegate>
{
    __weak IBOutlet UIScrollView *imageScrollView;
    __weak IBOutlet UIImageView *imageView ;
    
    __weak IBOutlet UIScrollView *imageEditToolbar;
    
    __weak IBOutlet UIView *bottomToolbar;
    __weak IBOutlet UIButton *btnQuitEdit;
    __weak IBOutlet UIButton *btnSaveEdit;
    __weak IBOutlet UIButton *btnRevokeEdit;
    __weak IBOutlet UIButton *btnRecoveryEdit;
    
    __weak IBOutlet UIView *editToolbar;
    __weak IBOutlet UIButton *btnCancelEdit;
    __weak IBOutlet UILabel *labelEditName;
    __weak IBOutlet UIButton *btnConfirmEdit;
    
    UIImage *originalImage ;
    UIImage *rstImage ;
    NSMutableArray *toolItemArray;
    NSMutableArray *editHistory ;
    KKImageEditType curtEditType ;
    
    LoadingIndicatorView *indicatorView;
    
    KKImageFilterTool *filterTool;
    KKImageEffectTool *effectTool;
    KKImageRotateTool *rotateTool;
    KKImageMosaicTool *mosaiTool ;
    KKImageDrawTool *drawTool ;
    KKImageClipTool *clipTool;
    KKEmoticonTool *emotionTool;
    KKPuzzleTool *puzzleTool; //拼图
    KKBlurTool *blurTool ;
    KKImageTextTool *textTool;
    
}
@end

@implementation KKImageEditController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil originalImage:(UIImage *)image
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self){
        
        toolItemArray = [[NSMutableArray alloc]init];
        editHistory = [[NSMutableArray alloc]init];
        curtEditType = -1 ;
        
        originalImage = image ;
        rstImage = image ;
        
        NSString *now = [self stringFromDate:[NSDate date] dateFormatter:@"yyyy-mm-dd hh:mm:ss"];
        NSString *path =  [NSTemporaryDirectory() stringByAppendingPathComponent:now] ;
        NSData *data = UIImagePNGRepresentation(originalImage);
        [data writeToFile:path atomically:YES];
        
        NSMutableDictionary *dicInfo = [[NSMutableDictionary alloc]initWithObjectsAndKeys:path,HISTORY_EDIT_IMAGEPATH,@"1",HISTORY_EDIT_CURTINDEX,nil];
        [editHistory addObject:dicInfo];
        
    }
    
    return self ;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [[UIApplication sharedApplication]setStatusBarHidden:YES];
    
    [self layoutUI];
    [self initEditToolBar];
    [self displayImage:originalImage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication]setStatusBarHidden:YES];
}

#pragma mark -- 初始化UI

- (void)layoutUI
{
    self.view.frame = [[UIScreen mainScreen]bounds];
    
    ///////////////////////////////////////////////////////
    
    imageScrollView.frame = CGRectMake(0, 0, self.view.width, self.view.height - imageEditToolbar.height - bottomToolbar.height - 5 - 5);
    imageScrollView.showsVerticalScrollIndicator = NO;
    imageScrollView.showsHorizontalScrollIndicator = NO;
    imageScrollView.bouncesZoom = YES;
    imageScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    imageScrollView.delegate = self;
    imageScrollView.bounces = YES ;
    
    imageView.frame = imageScrollView.bounds;
    imageView.userInteractionEnabled = YES ;
    [imageScrollView addSubview:imageView];
    
    ///////////////////////////////////////////////////////
    
    imageEditToolbar.frame = CGRectMake(0, imageScrollView.y + imageScrollView.height + 5, self.view.width, imageEditToolbar.height);
    
    ///////////////////////////////////////////////////////
    
    NSInteger midPos = self.view.width / 2 ;
    
    bottomToolbar.frame = CGRectMake(0, imageEditToolbar.y + imageEditToolbar.height + 5, self.view.width, bottomToolbar.height);
    bottomToolbar.hidden = NO ;
    
    btnQuitEdit.frame = CGRectMake(0, (bottomToolbar.height - btnQuitEdit.height ) / 2, btnQuitEdit.width, btnQuitEdit.height);
    
    btnSaveEdit.frame = CGRectMake((bottomToolbar.width - btnSaveEdit.width), (bottomToolbar.height - btnSaveEdit.height ) / 2, btnSaveEdit.width, btnSaveEdit.height);
    
    btnRevokeEdit.frame = CGRectMake(midPos - btnRevokeEdit.width, (bottomToolbar.height - btnRevokeEdit.height) / 2, btnRevokeEdit.width, btnRevokeEdit.height);
    btnRevokeEdit.enabled = false ;
    btnRevokeEdit.alpha = 0.5 ;
    
    btnRecoveryEdit.frame = CGRectMake(midPos, (bottomToolbar.height - btnRecoveryEdit.height) / 2, btnRecoveryEdit.width, btnRecoveryEdit.height);
    btnRecoveryEdit.enabled = false;
    btnRecoveryEdit.alpha = 0.5 ;
    
    ///////////////////////////////////////////////////////
    
    editToolbar.frame = bottomToolbar.frame;
    editToolbar.hidden = YES ;
    
    btnCancelEdit.frame = CGRectMake(0, (editToolbar.height - btnCancelEdit.height ) / 2, btnCancelEdit.width, btnCancelEdit.height);
    
    btnConfirmEdit.frame = CGRectMake((editToolbar.width - btnConfirmEdit.width), (editToolbar.height - btnConfirmEdit.height ) / 2, btnConfirmEdit.width, btnConfirmEdit.height);
    
    labelEditName.frame = CGRectMake((editToolbar.width - labelEditName.width) / 2, (editToolbar.height - labelEditName.height) / 2, labelEditName.width, labelEditName.height);
}

#pragma mark -- 显示图片

- (void)displayImage:(UIImage *)image
{
    imageView.image = image ;
    
    CGSize size = (imageView.image) ? imageView.image.size : imageView.frame.size;
    
    if(size.width>0 && size.height>0){
        [self resetImageViewFrameAndZoomScaleWithSize:size];
    }
}

#pragma mark -- 重置UIImageView大小及UIScrollView缩放

- (void)resetImageViewFrameAndZoomScaleWithSize:(CGSize)size
{
    CGFloat ratio = MIN(imageScrollView.frame.size.width / size.width, imageScrollView.frame.size.height / size.height);
    CGFloat W = ratio * size.width;
    CGFloat H = ratio * size.height;
    
    imageView.frame = CGRectMake(MAX(0, (imageScrollView.width-W)/2), MAX(0, (imageScrollView.height-H)/2), W, H);
    
    CGFloat Rw = imageScrollView.frame.size.width / imageView.frame.size.width;
    CGFloat Rh = imageScrollView.frame.size.height / imageView.frame.size.height;
    
    CGFloat scale = 1;
    Rw = MAX(Rw, imageView.image.size.width / (scale * imageScrollView.frame.size.width));
    Rh = MAX(Rh, imageView.image.size.height / (scale * imageScrollView.frame.size.height));
    
    imageScrollView.contentSize = imageView.frame.size;
    imageScrollView.minimumZoomScale = 1;
    imageScrollView.maximumZoomScale = MAX(MAX(Rw, Rh), 1);
    
    [imageScrollView setZoomScale:imageScrollView.minimumZoomScale animated:YES];
}

#pragma mark -- 编辑的时候，恢复UIScrollView的缩放比例

- (void)fixZoomScaleWithAnimated:(BOOL)animated
{
    CGFloat minZoomScale = imageScrollView.minimumZoomScale;
    imageScrollView.maximumZoomScale = 1*minZoomScale;
    imageScrollView.minimumZoomScale = 1*minZoomScale;
    [imageScrollView setZoomScale:imageScrollView.minimumZoomScale animated:animated];
}

#pragma mark -- UIScrollView  图片缩放

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if(scrollView == imageScrollView){
        
        //缩放过程中实时调整图片位置以便居中显示
        CGFloat Ws = scrollView.frame.size.width - scrollView.contentInset.left - scrollView.contentInset.right;
        CGFloat Hs = scrollView.frame.size.height - scrollView.contentInset.top - scrollView.contentInset.bottom;
        CGFloat W = imageView.frame.size.width;
        CGFloat H = imageView.frame.size.height;
        
        CGRect rct = imageView.frame;
        rct.origin.x = MAX((Ws-W)/2, 0);
        rct.origin.y = MAX((Hs-H)/2, 0);
        imageView.frame = rct;
        
    }
}

#pragma mark -- 初始化图片编辑工具类

- (void)initEditToolBar
{
    KKImageEditToolItem *itemFilter = [[KKImageEditToolItem alloc]init];
    itemFilter.itemImage = [UIImage imageNamed:@"filter"];
    itemFilter.itemTitle = @"滤镜";
    itemFilter.delegate = self ;
    itemFilter.editType = KKImageEditTypeFilter ;
    itemFilter.editInfo = nil ;
    itemFilter.selected = NO ;
    [toolItemArray addObject:itemFilter];
    
    KKImageEditToolItem *itemEffect = [[KKImageEditToolItem alloc]init];
    itemEffect.itemImage = [UIImage imageNamed:@"effect"];
    itemEffect.itemTitle = @"效果";
    itemEffect.delegate = self ;
    itemEffect.editType = KKImageEditTypeEffect ;
    itemEffect.editInfo = nil ;
    itemEffect.selected = NO ;
    [toolItemArray addObject:itemEffect];
    
    KKImageEditToolItem *itemRotate = [[KKImageEditToolItem alloc]init];
    itemRotate.itemImage = [UIImage imageNamed:@"rotate"];
    itemRotate.itemTitle = @"旋转";
    itemRotate.delegate = self ;
    itemRotate.editType = KKImageEditTypeRotate ;
    itemRotate.editInfo = nil ;
    itemRotate.selected = NO ;
    [toolItemArray addObject:itemRotate];
    
    KKImageEditToolItem *itemMosaic = [[KKImageEditToolItem alloc]init];
    itemMosaic.itemImage = [UIImage imageNamed:@"mosaic"];
    itemMosaic.itemTitle = @"马赛克";
    itemMosaic.delegate = self ;
    itemMosaic.editType = KKImageEditTypeMosaic ;
    itemMosaic.editInfo = nil ;
    itemMosaic.selected = NO ;
    [toolItemArray addObject:itemMosaic];
    
    KKImageEditToolItem *itemDraw = [[KKImageEditToolItem alloc]init];
    itemDraw.itemImage = [UIImage imageNamed:@"draw"];
    itemDraw.itemTitle = @"绘制";
    itemDraw.delegate = self ;
    itemDraw.editType = KKImageEditTypeDraw ;
    itemDraw.editInfo = nil ;
    itemDraw.selected = NO ;
    [toolItemArray addObject:itemDraw];
    
    KKImageEditToolItem *itemClip = [[KKImageEditToolItem alloc]init];
    itemClip.itemImage = [UIImage imageNamed:@"clip"];
    itemClip.itemTitle = @"裁剪";
    itemClip.delegate = self ;
    itemClip.editType = KKImageEditTypeClip ;
    itemClip.editInfo = nil ;
    itemClip.selected = NO ;
    [toolItemArray addObject:itemClip];
    
    KKImageEditToolItem *itemEmotion = [[KKImageEditToolItem alloc]init];
    itemEmotion.itemImage = [UIImage imageNamed:@"emotion"];
    itemEmotion.itemTitle = @"表情";
    itemEmotion.delegate = self ;
    itemEmotion.editType = KKImageEditTypeEmotion ;
    itemEmotion.editInfo = nil ;
    itemEmotion.selected = NO ;
    [toolItemArray addObject:itemEmotion];
    
    KKImageEditToolItem *itemPuzzle = [[KKImageEditToolItem alloc]init];
    itemPuzzle.itemImage = [UIImage imageNamed:@"puzzle"];
    itemPuzzle.itemTitle = @"拼图";
    itemPuzzle.delegate = self ;
    itemPuzzle.editType = KKImageEditTypePuzzle ;
    itemPuzzle.editInfo = nil ;
    itemPuzzle.selected = NO ;
    [toolItemArray addObject:itemPuzzle];
    
    KKImageEditToolItem *itemBlur = [[KKImageEditToolItem alloc]init];
    itemBlur.itemImage = [UIImage imageNamed:@"blur"];
    itemBlur.itemTitle = @"模糊";
    itemBlur.delegate = self ;
    itemBlur.editType = KKImageEditTypeBlur ;
    itemBlur.editInfo = nil ;
    itemBlur.selected = NO ;
    [toolItemArray addObject:itemBlur];
    
    KKImageEditToolItem *itemText = [[KKImageEditToolItem alloc]init];
    itemText.itemImage = [UIImage imageNamed:@"text"];
    itemText.itemTitle = @"文字";
    itemText.delegate = self ;
    itemText.editType = KKImageEditTypeText ;
    itemText.editInfo = nil ;
    itemText.selected = NO ;
    [toolItemArray addObject:itemText];
    
    CGFloat x = 0;
    CGFloat W = 50;
    CGFloat H = imageEditToolbar.height;
    CGFloat padding = 5 ;

    for(KKImageEditToolItem *item in toolItemArray){
        
        item.frame = CGRectMake(x, 0, W, H);
        
        [imageEditToolbar addSubview:item];
        
        x += (W + padding);
    }
    
    imageEditToolbar.contentSize = CGSizeMake(MAX(x, imageEditToolbar.frame.size.width+1), 0);
}

#pragma mark -- IBAction

- (IBAction)quitEditController:(id)sender
{
    [[UIApplication sharedApplication]setStatusBarHidden:NO];
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)revokeEdit:(id)sender
{
    NSInteger index = -1 ;
    for(NSInteger i = 0 ; i < editHistory.count ; i++){
        NSMutableDictionary *dicInfo = [editHistory objectAtIndex:i];
        if([[dicInfo objectForKey:HISTORY_EDIT_CURTINDEX]isEqualToString:@"1"]){
            [dicInfo setObject:@"0" forKey:HISTORY_EDIT_CURTINDEX];
            index = i ;
            break ;
        }
    }
    
    if(index > 0){
        
        NSMutableDictionary *dicInfo = [editHistory objectAtIndex:index - 1];
        NSString *path = [dicInfo objectForKey:HISTORY_EDIT_IMAGEPATH];
        originalImage = [UIImage imageWithContentsOfFile:path];
        rstImage = originalImage ;
        
        [self displayImage:originalImage];
        
        [dicInfo setObject:@"1" forKey:HISTORY_EDIT_CURTINDEX];
        
        if((index - 1 ) == 0){
            [self enableRevoke:false];
        }
        
        [self enableRecovery:true];
    }
}

- (IBAction)recoveryEdit:(id)sender
{
    NSInteger index = -1 ;
    for(NSInteger i = 0 ; i < editHistory.count ; i++){
        NSMutableDictionary *dicInfo = [editHistory objectAtIndex:i];
        if([[dicInfo objectForKey:HISTORY_EDIT_CURTINDEX]isEqualToString:@"1"]){
            [dicInfo setObject:@"0" forKey:HISTORY_EDIT_CURTINDEX];
            index = i ;
            break ;
        }
    }
    
    if(index >= 0 && index < editHistory.count - 1){
        
        NSMutableDictionary *dicInfo = [editHistory objectAtIndex:index + 1];
        NSString *path = [dicInfo objectForKey:HISTORY_EDIT_IMAGEPATH];
        originalImage = [UIImage imageWithContentsOfFile:path];
        rstImage = originalImage ;
        
        [self displayImage:originalImage];
        
        [dicInfo setObject:@"1" forKey:HISTORY_EDIT_CURTINDEX];
        
        if((index + 1 ) == (editHistory.count - 1)){
            [self enableRecovery:false];
        }
        
        [self enableRevoke:true];
    }
}

- (IBAction)saveEdit:(id)sender
{
    [self showIndicatorView];
    
    NSString *album = [[KKPhotoManager shareInstance]getCameraRollAlbumId];
    
    //TODO:多语言
    [[KKPhotoManager shareInstance]addImageToAlbumWithImage:originalImage
                                                    albumId:album
                                                    options:nil
                                                      block:^(BOOL suc)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideIndicatorView];
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"保存成功" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alertView show];
        });
    }];
}

- (IBAction)cancelEdit:(id)sender
{
    [self displayImage:originalImage];
    
    imageEditToolbar.scrollEnabled = YES ;
    bottomToolbar.hidden = NO ;
    editToolbar.hidden = YES ;
    
    [self cleanupUI];
    
}

- (IBAction)confirmEdit:(id)sender
{
    if(curtEditType == KKImageEditTypeEffect){
        
        [self showIndicatorView];
        
        [effectTool effectImage:originalImage block:^(UIImage *image) {
            
            rstImage = image;
            originalImage = rstImage ;
            
            [self saveChangeRestlt];
            
        }];
        
    }else if(curtEditType == KKImageEditTypeRotate){
        
        [self showIndicatorView];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            rstImage = [rotateTool buildImage:originalImage];
            originalImage = rstImage ;
            
            [self saveChangeRestlt];
            
        });
        
    }else if(curtEditType == KKImageEditTypeMosaic){
        
        [self showIndicatorView];
        
        [mosaiTool genMosaicImageWithBlock:^(UIImage *image, NSError *erroe, NSDictionary *info) {
            
            rstImage = image;
            originalImage = rstImage ;
            
            [self saveChangeRestlt];
            
        }];
        
    }else if(curtEditType == KKImageEditTypeDraw){
        
        [self showIndicatorView];
        
        [drawTool genDrawImageWithBlock:^(UIImage *image, NSError *error, NSDictionary *info) {
            
            rstImage = image;
            originalImage = rstImage ;
            
            [self saveChangeRestlt];
            
        }];
        
    }else if(curtEditType == KKImageEditTypeClip){
        
        [self showIndicatorView];
        
        [clipTool clipImageWithBlock:^(UIImage *image, NSError *error, NSDictionary *info) {
            
            rstImage = image;
            originalImage = rstImage ;
            
            [self saveChangeRestlt];
            
        }];
        
    }else if(curtEditType == KKImageEditTypeFilter){
        
        [self showIndicatorView];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            rstImage = [filterTool filteredImage:originalImage withFilterName:filterTool.curtFilterName];
            
            originalImage = rstImage ;
            
            [self saveChangeRestlt];
            
        });
        
    }else if(curtEditType == KKImageEditTypeEmotion){
        
        [self showIndicatorView];
        
        [emotionTool genEmotionImageWithBlock:^(UIImage *image) {
            
            rstImage = image ;
            
            originalImage = rstImage ;
            
            [self saveChangeRestlt];
            
        }];
        
    }else if(curtEditType == KKImageEditTypePuzzle){
        
        [self showIndicatorView];
        
        [puzzleTool genPuzzleImageWithBlock:^(UIImage *image) {
            
            rstImage = image ;
            
            originalImage = rstImage ;
            
            [self saveChangeRestlt];
            
        }];
        
    }else if(curtEditType == KKImageEditTypeBlur){
        
        [self showIndicatorView];
        
        [blurTool genBlurImageWithBlock:^(UIImage *image) {
            
            rstImage = image ;
            
            originalImage = rstImage ;
            
            [self saveChangeRestlt];
            
        }];
        
    }else if(curtEditType == KKImageEditTypeText){
        
        [self showIndicatorView];
        
        [textTool genEditTextImageWithBlock:^(UIImage *image) {
            
            rstImage = image ;
            
            originalImage = rstImage ;
            
            [self saveChangeRestlt];
            
        }];
        
    }
    
    imageEditToolbar.scrollEnabled = YES ;
    bottomToolbar.hidden = NO ;
    editToolbar.hidden = YES ;
    
    [self enableRevoke:true];
    [self enableRecovery:false];
}

#pragma mark -- 保存编辑结果

- (void)saveChangeRestlt
{
    NSString *now = [self stringFromDate:[NSDate date] dateFormatter:@"yyyy-mm-dd hh:mm:ss"];
    NSString *path =  [NSTemporaryDirectory() stringByAppendingPathComponent:now] ;
    NSData *data = UIImagePNGRepresentation(originalImage);
    [data writeToFile:path atomically:YES];
    
    for(NSMutableDictionary *dicInfo in editHistory){
        [dicInfo setObject:@"0" forKey:HISTORY_EDIT_CURTINDEX];
    }
    
    NSMutableDictionary *dicInfo = [[NSMutableDictionary alloc]initWithObjectsAndKeys:path,HISTORY_EDIT_IMAGEPATH,@"1",HISTORY_EDIT_CURTINDEX,nil];
    [editHistory addObject:dicInfo];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self hideIndicatorView];
        [self cleanupUI];
        [self displayImage:originalImage];
        
        
    });
}

#pragma mark -- 清理编辑界面

- (void)cleanupUI
{
    [effectTool cleanup];
    [filterTool cleanup];
    [rotateTool cleanup];
    [mosaiTool cleanup];
    [drawTool cleanup];
    [clipTool cleanup];
    [emotionTool cleanup];
    [puzzleTool cleanup];
    [blurTool cleanup];
    [textTool cleanup];
}

#pragma mark -- 设置撤销按钮是否可用

- (void)enableRevoke:(BOOL)enable
{
    btnRevokeEdit.enabled = enable ;
    btnRevokeEdit.alpha = (enable ? 1.0 : 0.5);
}

#pragma mark -- 设置恢复按钮是否可用

- (void)enableRecovery:(BOOL)enable
{
    btnRecoveryEdit.enabled = enable ;
    btnRecoveryEdit.alpha = (enable ? 1.0 : 0.5);
}

#pragma mark -- KKImageEditToolItemDelegate

- (void)imageEditItem:(KKImageEditToolItem *)item clickItemWithType:(KKImageEditType)editType editInfo:(NSDictionary *)editInfo
{
    curtEditType = editType ;
    
    if(editType == KKImageEditTypeFilter){
        
        imageEditToolbar.scrollEnabled = NO ;
        bottomToolbar.hidden = YES ;
        editToolbar.hidden = NO ;
        labelEditName.text = @"滤镜";
        
        [self fixZoomScaleWithAnimated:YES];
        
        filterTool = [[KKImageFilterTool alloc]init];
        [filterTool setupWithSuperView:imageScrollView
                        imageViewFrame:imageView.frame
                              menuView:imageEditToolbar
                                 image:originalImage
                            applyBlock:^(UIImage *image)
        {
            rstImage = image ;
            
            [self displayImage:rstImage];
            
        }];
        
    }else if(editType == KKImageEditTypeEffect){
        
        imageEditToolbar.scrollEnabled = NO ;
        bottomToolbar.hidden = YES ;
        editToolbar.hidden = NO ;
        labelEditName.text = @"效果";
        
        [self fixZoomScaleWithAnimated:YES];
        
        effectTool = [[KKImageEffectTool alloc]init];
        [effectTool setupWithSuperView:imageScrollView
                        imageViewFrame:imageView.frame
                              menuView:imageEditToolbar
                                 image:originalImage
                            applyBlock:^(UIImage *image)
        {
            rstImage = image;

            [self displayImage:rstImage];
            
        }];
        
    }else if(editType == KKImageEditTypeRotate){
        
        imageEditToolbar.scrollEnabled = NO ;
        bottomToolbar.hidden = YES ;
        editToolbar.hidden = NO ;
        labelEditName.text = @"翻转";
        
        [self fixZoomScaleWithAnimated:YES];
        
        rotateTool = [[KKImageRotateTool alloc]init];
        [rotateTool setupWithSuperView:imageScrollView imageViewFrame:imageView.frame menuView:imageEditToolbar image:originalImage];
        
    }else if(editType == KKImageEditTypeMosaic){
            
        imageEditToolbar.scrollEnabled = NO ;
        bottomToolbar.hidden = YES ;
        editToolbar.hidden = NO ;
        labelEditName.text = @"马赛克";
        
        [self fixZoomScaleWithAnimated:YES];
        
        mosaiTool = [[KKImageMosaicTool alloc]init];
        [mosaiTool setupWithSuperView:imageScrollView imageViewFrame:imageView.frame menuView:imageEditToolbar image:originalImage];
        
    }else if(editType == KKImageEditTypeDraw){
            
        imageEditToolbar.scrollEnabled = NO ;
        bottomToolbar.hidden = YES ;
        editToolbar.hidden = NO ;
        labelEditName.text = @"绘制";
        
        [self fixZoomScaleWithAnimated:YES];
        
        drawTool = [[KKImageDrawTool alloc]init];
        [drawTool setupWithSuperView:imageScrollView imageViewFrame:imageView.frame menuView:imageEditToolbar image:originalImage];
        
    }else if(editType == KKImageEditTypeClip){
            
        imageEditToolbar.scrollEnabled = NO ;
        bottomToolbar.hidden = YES ;
        editToolbar.hidden = NO ;
        labelEditName.text = @"裁剪";
        
        [self fixZoomScaleWithAnimated:YES];
        
        clipTool = [[KKImageClipTool alloc]init];
        [clipTool setupWithSuperView:imageScrollView imageViewFrame:imageView.frame menuView:imageEditToolbar image:originalImage];
        
    }else if(editType == KKImageEditTypeEmotion){
        
        imageEditToolbar.scrollEnabled = NO ;
        bottomToolbar.hidden = YES ;
        editToolbar.hidden = NO ;
        labelEditName.text = @"表情";
        
        [self fixZoomScaleWithAnimated:YES];
        
        emotionTool = [[KKEmoticonTool alloc]init];
        [emotionTool setupWithSuperView:imageScrollView imageViewFrame:imageView.frame menuView:imageEditToolbar image:originalImage];
        
    }else if(editType == KKImageEditTypePuzzle){
        
        KKPuzzImageSelectController *ctrl = [[KKPuzzImageSelectController alloc]initWithNibName:@"KKPuzzImageSelectController" bundle:nil];
        ctrl.delegate = self ;

        KKNavViewController *nav = [[KKNavViewController alloc]initWithRootViewController:ctrl];
        
        [self presentViewController:nav animated:YES completion:^{
            
        }];
        
    }else if(editType == KKImageEditTypeBlur){
        
        imageEditToolbar.scrollEnabled = NO ;
        bottomToolbar.hidden = YES ;
        editToolbar.hidden = NO ;
        labelEditName.text = @"模糊";
        
        [self fixZoomScaleWithAnimated:YES];
        
        blurTool = [[KKBlurTool alloc]init];
        [blurTool setupWithSuperView:imageScrollView imageViewFrame:imageView.frame menuView:imageEditToolbar image:originalImage];
        
    }else if(editType == KKImageEditTypeText){
        
        imageEditToolbar.scrollEnabled = NO ;
        bottomToolbar.hidden = YES ;
        editToolbar.hidden = NO ;
        labelEditName.text = @"文字";
        
        [self fixZoomScaleWithAnimated:YES];
        
        textTool = [[KKImageTextTool alloc]init];
        [textTool setupWithSuperView:imageScrollView imageViewFrame:imageView.frame menuView:imageEditToolbar image:originalImage];
        
    }
}

#pragma mark -- startPuzzleImageDelegate

- (void)startPuzzleWithImageAssets:(NSArray *)assetArray
{
    imageEditToolbar.scrollEnabled = NO ;
    bottomToolbar.hidden = YES ;
    editToolbar.hidden = NO ;
    labelEditName.text = @"拼图";
    
    [self fixZoomScaleWithAnimated:YES];
    
    puzzleTool = [[KKPuzzleTool alloc]init];
    [puzzleTool setupWithSuperView:imageScrollView imageViewFrame:imageView.frame menuView:imageEditToolbar puzzleImageArray:assetArray];
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

#pragma mark -- 屏幕旋转

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return NO ;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait ;
}

#pragma mark -- 日期转字符串

- (NSString *)stringFromDate:(NSDate *)date dateFormatter:(NSString *)format
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = format;
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    return strDate;
}

@end
