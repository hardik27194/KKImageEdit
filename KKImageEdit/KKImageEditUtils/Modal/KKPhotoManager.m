//
//  KKPhotoManager.m
//
//  Created by finger on 16/10/9.
//  Copyright © 2016年 finger. All rights reserved.
//

#import "KKPhotoManager.h"

@interface KKPhotoManager()<PHPhotoLibraryChangeObserver>
{
    PHCachingImageManager *cachingImageManager;//照片缓存，每次获取照片时先从缓存中查找
    
    //注意，这两个变量只为了提高UICollectionView或者UItableView显示效率,不能用于其他模块的相片获取
    PHAssetCollection *albumCollection;//每一个相册对应一个PHAssetCollection
    PHFetchResult *albumAssets;//每一个相册的相片集合对应一个PHFetchResult
    
}
@end

@implementation KKPhotoManager

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    static KKPhotoManager *imageMgr;
    dispatch_once(&onceToken, ^{
        imageMgr = [[KKPhotoManager alloc]init];
    });
    return imageMgr;
}

- (void)dealloc
{
    PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    [photoLibrary unregisterChangeObserver:self];
}

- (id)init
{
    self = [super init];
    
    if (self){
        
        albumAssets = nil;
        albumCollection = nil;
        cachingImageManager = [[PHCachingImageManager alloc] init];
        
        PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
        [photoLibrary registerChangeObserver:self];
        
    }
    
    return self;
}

#pragma mark -- 照片库变动通知

- (void)photoLibraryDidChange:(PHChange *)changeInstance;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyPhotoLibraryDidChange object:nil];
}

#pragma mark -- 用户权限

- (KKPhotoAuthorizationStatus )convertStatusWithPHAuthorizationStatus:(PHAuthorizationStatus)PHStatus
{
    switch (PHStatus)
    {
        case PHAuthorizationStatusNotDetermined:
            return KKPhotoAuthorizationStatusNotDetermined;
        case PHAuthorizationStatusDenied:
            return KKPhotoAuthorizationStatusDenied;
        case PHAuthorizationStatusRestricted:
            return KKPhotoAuthorizationStatusRestricted;
        case PHAuthorizationStatusAuthorized:
            return KKPhotoAuthorizationStatusAuthorized;
        default:
            return KKPhotoAuthorizationStatusRestricted;
    }
}

- (KKPhotoAuthorizationStatus)authorizationStatus
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    return [self convertStatusWithPHAuthorizationStatus:status];
}

- (void)requestAuthorization:(void (^)(KKPhotoAuthorizationStatus))handler
{
    __weak typeof(self)weakSelf = self ;
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if(handler){
            handler([weakSelf convertStatusWithPHAuthorizationStatus:status]);
        }
    }];
}

#pragma mark -- 获取相机胶卷相册的id

- (NSString*)getCameraRollAlbumId
{
    PHFetchResult *collectionsResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    for (int i = 0; i < collectionsResult.count; i++){
        PHAssetCollection *collection = collectionsResult[i];
        NSInteger assetSubType = collection.assetCollectionSubtype ;
        if (assetSubType == PHAssetCollectionSubtypeSmartAlbumUserLibrary){
            return [collection.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        }
    }
    return nil ;
}

#pragma mark -- 根据相册的id获取相册的PHFetchResult

- (PHFetchResult *)getAlbumAssetsWithAlbunId:(NSString *)albumId
{
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
    
    PHAssetCollection *collection = [self getAlbumCollectionWithAlbumId:albumId];
    
    PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    
    return assets ;
}

#pragma mark -- 获取相片列表

- (void)getAlbumImageWithComparison:(NSComparisonResult)comparison
                           albumObj:(NSObject *)collection
                              block:(void(^)(NSArray *result))handler
{
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:(comparison == NSOrderedAscending)?YES:NO]];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
    
    [self getAlbumCollectionWithAlbumId:(NSString *)collection block:^(PHAssetCollection *callback){
        
        albumCollection = callback;
        albumAssets = [PHAsset fetchAssetsInAssetCollection:albumCollection options:options];
        
        NSString *lastCreateDate = @"";
        NSMutableArray *itemArr = nil;
        NSMutableArray *localIdArray = nil ;
        NSMutableDictionary *dic = nil;
        NSMutableArray *theResult = [NSMutableArray arrayWithCapacity:0];
        
        NSString *dataFormatter = @"YYYY-MM-dd";;
        
        for (int i = 0 ; i <albumAssets.count ; i++){
            
            PHAsset *asset = albumAssets[i];
            if (asset == nil || asset.mediaType != PHAssetMediaTypeImage){
                continue;
            }
            
            NSString *createDate = [self stringFromDate:asset.creationDate dateFormatter:dataFormatter];
            if (![lastCreateDate isEqualToString:createDate]){
                
                lastCreateDate = createDate;
                
                dic = [[NSMutableDictionary alloc] initWithCapacity:0];
                [dic setObject:createDate forKey:kGroupTitle];
                
                itemArr = [[NSMutableArray alloc] initWithCapacity:0];
                [dic setObject:itemArr forKey:kItems];
                
                localIdArray = [[NSMutableArray alloc] initWithCapacity:0];
                [dic setObject:localIdArray forKey:kLocalIdentifierArray];
                
                [theResult addObject:dic];
            }
            
            //传递的值为当前图片在相机胶卷内的index
            [itemArr addObject:[NSString stringWithFormat:@"%d",i]];
            
            NSString *localIdentifier = [asset.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
            [localIdArray addObject:localIdentifier];
            
        }
        
        handler(theResult);
        
    }];
    
}

#pragma mark - 图片获取，albumCollection和albumAssets在调用之前必须先初始化

- (void)getThumbnailImageWithIndex:(NSInteger)index
                     needImageSize:(CGSize)size
                    isNeedDegraded:(BOOL)degraded
                              sort:(NSComparisonResult)comparison
                             block:(void(^)(UIImage *image,NSDictionary *userInfo))handler
{
    if (albumAssets.count - 1 < index) {
        return;
    }
    
    if (albumCollection && albumAssets){
        
        
        
        [self getThumbnailImageWithAlbumAsset:albumAssets
                                        index:index
                                needImageSize:size
                               isNeedDegraded:degraded
                                         sort:comparison
                                        block:^(UIImage *image,NSDictionary *userInfo)
         {
             handler(image,userInfo);
         }];
        
    }else{
        handler(nil,nil);
    }
}

- (void)getThumbnailImageWithAlbumAsset:(PHFetchResult *)assetsResult
                                  index:(NSInteger)index
                          needImageSize:(CGSize)size
                         isNeedDegraded:(BOOL)degraded
                                   sort:(NSComparisonResult)comparison
                                  block:(void(^)(UIImage *image,NSDictionary *userInfo))handler
{
    if (index < assetsResult.count){
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
        options.networkAccessAllowed = YES ;
        
        PHAsset *asset = assetsResult[index];
        if(!asset){
            handler(nil,nil);
            return ;
        }
        
        NSString *localIdentifier = [asset.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc]initWithObjectsAndKeys:localIdentifier,kLocalIdentifier, nil];
        
        [cachingImageManager requestImageForAsset:asset
                                       targetSize:size
                                      contentMode:PHImageContentModeAspectFill
                                          options:options
                                    resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info)
         {
             if (degraded == YES){
                 
                 handler(result,userInfo);
                 
             }else{
                 
                 //PHImageResultIsDegradedKey  的值为1时，表示为小尺寸的缩略图，此时还在下载原尺寸的图
                 BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                 
                 if (isDegraded == NO){
                     handler(result,userInfo);
                 }
                 
             }
             
         }];
        
    }else{
        handler(nil,nil);
    }
}

//TODO:获取全屏显示的照片，注意，在照片的尺寸特别大的情况下，加载原图会导致内存暴增而崩溃(原因不明)，需要重新调整获取图片的大小

- (void)getDisplayImageWithAlbumID:(NSString *)albumID
                             index:(NSInteger)index
                     needImageSize:(CGSize)size
                    isNeedDegraded:(BOOL)degraded
                              sort:(NSComparisonResult)comparison
                             block:(void (^)(UIImage *, NSDictionary *))handler
{
    __weak typeof(self)weakSelf = self ;
    
    [self getAlbumCollectionWithAlbumId:albumID block:^(PHAssetCollection *collection) {
        
        if (collection != nil){
            
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            
            BOOL isAscending = YES;
            if (comparison == NSOrderedDescending){
                isAscending = NO;
            }
            
            options.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:isAscending]];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            
            if (fetchResult.count == 0){
                
                handler(nil,UIImageOrientationUp);
                
                return ;
                
            }
            
            PHAsset *asset = fetchResult[index];
            if(!asset){
                handler(nil,nil);
                return ;
            }
            
            CGSize theSize = size;
            
            //重新调整原图的大小
            if (CGSizeEqualToSize(size, CGSizeZero) == YES){
                
                CGFloat minRatio = 1.0 ;
                CGFloat scale = [UIScreen mainScreen].scale ;
                CGRect mainScreen = [UIScreen mainScreen].bounds;
                CGFloat targetWidth = 2 * mainScreen.size.width * scale ;
                CGFloat targetHeight = 2 * mainScreen.size.height * scale ;
                if(asset.pixelWidth > targetWidth || asset.pixelHeight > targetHeight){
                    minRatio = MIN(targetWidth / asset.pixelWidth, targetHeight / asset.pixelHeight);
                }
                theSize = CGSizeMake(asset.pixelWidth * minRatio,asset.pixelHeight * minRatio);
                
            }
            
            PHImageRequestOptions *requireOptions = [[PHImageRequestOptions alloc]init];
            requireOptions.networkAccessAllowed = YES ;
            
            [weakSelf requestImageFromCacheWithAsset:asset
                                          targetSize:theSize
                                         contentMode:PHImageContentModeAspectFill
                                             options:requireOptions
                                      isNeedDegraded:degraded
                                               block:^(UIImage *image, NSDictionary *userInfo)
             {
                 handler(image,userInfo);
             }];
            
        }else{
            handler(nil,nil);
        }
    }];
}

#pragma mark -- 根据相册id和图片索引获取图片

- (void)getImageWithAlbumID:(NSString *)albumID
                      index:(NSInteger)index
              needImageSize:(CGSize)size
             isNeedDegraded:(BOOL)degraded
                       sort:(NSComparisonResult)comparison
                      block:(void (^)(UIImage *, NSDictionary *))handler
{
    __weak typeof(self)weakSelf = self ;
    
    [self getAlbumCollectionWithAlbumId:albumID block:^(PHAssetCollection *collection) {
        
        if (collection != nil){
            
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            
            BOOL isAscending = YES;
            if (comparison == NSOrderedDescending){
                isAscending = NO;
            }
            
            options.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:isAscending]];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            
            if (fetchResult.count == 0){
                
                handler(nil,UIImageOrientationUp);
                
                return ;
                
            }
            
            PHImageRequestOptions *requireOptions = [[PHImageRequestOptions alloc]init];
            requireOptions.networkAccessAllowed = YES ;
            
            PHAsset *asset = fetchResult[index];
            if(!asset){
                handler(nil,nil);
                return ;
            }
            
            [weakSelf requestImageFromCacheWithAsset:asset
                                          targetSize:size
                                         contentMode:PHImageContentModeAspectFill
                                             options:requireOptions
                                      isNeedDegraded:degraded
                                               block:^(UIImage *image, NSDictionary *userInfo)
             {
                 handler(image,userInfo);
             }];
            
        }else{
            handler(nil,nil);
        }
    }];
}

#pragma mark -- 根据相册id，图片索引，获取图片数据(NSData)

- (void)getImageDataWithAlbumID:(NSString *)albumID
                          index:(NSInteger)index
                           sort:(NSComparisonResult)comparison
                          block:(void (^)(NSData *, NSDictionary *))handler
{
    __weak typeof(self)weakSelf = self ;
    
    [self getAlbumCollectionWithAlbumId:albumID block:^(PHAssetCollection *collection) {
        
        if (collection != nil){
            
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:(comparison == NSOrderedAscending)?YES:NO]];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
            PHFetchResult *assetsResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            
            PHAsset *asset = assetsResult[index];
            if(!asset){
                handler(nil,nil);
                return ;
            }
            
            PHImageRequestOptions *requireOptions = [[PHImageRequestOptions alloc]init];
            requireOptions.networkAccessAllowed = YES ;
            
            [weakSelf requestImageDataWithAlbumId:albumID
                                            asset:asset
                                          options:requireOptions
                                            block:^(NSData *imageData, NSDictionary *userInfo)
             {
                 handler(imageData,userInfo);
             }];
            
        }else{
            handler(nil,UIImageOrientationUp);
        }
    }];
}

#pragma mark -- 从图片缓存中获取数据(NSData)

- (void)requestImageDataWithAlbumId:(NSString *)albumId
                              asset:(PHAsset *)asset
                            options:(PHImageRequestOptions *)options
                              block:(void(^)(NSData *imageData ,NSDictionary *userInfo))handler
{
    __block NSMutableDictionary *imageDic = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    __block NSData * imageRstData = nil ;
    
    if(!albumId.length || !asset){
        handler(nil,nil);
        return ;
    }
    
    @autoreleasepool {
        
        [cachingImageManager requestImageDataForAsset:asset
                                              options:options
                                        resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info)
         {
             if (info || imageData) {
                 
                 imageRstData = imageData ;
                 
                 NSDate *createDate = asset.creationDate;
                 NSString *imageTitle = [[info objectForKey:@"PHImageFileURLKey"] lastPathComponent];
                 if (imageTitle == nil){
                     imageTitle = [self stringFromDate:createDate dateFormatter:@"MMddyyyy"];
                 }
                 [imageDic setObject:imageTitle forKey:kItemTitle];
                 
                 [imageDic setObject:albumId forKey:kGroupId];
                 [imageDic setObject:[self stringFromDate:createDate dateFormatter:@"yyyy/MM/dd hh:mm:ss"] forKey:kItemCreateDate];
                 [imageDic setObject:[self stringFromDate:asset.modificationDate dateFormatter:@"yyyy/MM/dd hh:mm:ss"] forKey:kItemModifyDate];
                 [imageDic setObject:[NSNumber numberWithInteger:asset.pixelWidth] forKey:kItemWidth];
                 [imageDic setObject:[NSNumber numberWithInteger:asset.pixelHeight] forKey:kItemHeight];
                 [imageDic setObject:[NSNumber numberWithLongLong:imageRstData.length] forKey:kItemDataSize];
                 
                 NSString *localIdentifier = [asset.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                 [imageDic setObject:localIdentifier forKey:kLocalIdentifier];
                 
                 handler(imageRstData,imageDic);
                 
             }else{
                 handler(nil, nil);
             }
             
         }];
        
    }
}

#pragma mark - 获取PHAssetCollection 句柄

- (PHAssetCollection *)getAlbumCollectionWithAlbumId:(NSString *)albumId
{
    //获取系统相册
    PHFetchResult *smartAlbumsResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    if (smartAlbumsResult != nil){
        
        NSInteger albumCount = smartAlbumsResult.count;
        
        if ( albumCount > 0 ){
            
            for (int i = 0; i < albumCount; i++){
                
                PHAssetCollection *collection = smartAlbumsResult[i];
                
                if ([[collection.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"] isEqualToString:albumId]){
                    
                    return collection;
                    
                }
            }
        }
    }
    
    //自定义相册
    PHFetchResult *customAlbumsResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    
    if (customAlbumsResult != nil){
        
        NSInteger albumCount = customAlbumsResult.count;
        
        if (albumCount >0 ){
            
            for (int i = 0; i < albumCount; i++){
                
                PHAssetCollection *collection = customAlbumsResult[i];
                
                if ([[collection.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"] isEqualToString:albumId]){
                    
                    return collection;
                    
                }
            }
        }
    }
    
    return nil;
    
}

- (void)getAlbumCollectionWithAlbumId:(NSString *)albumId block:(void(^)(PHAssetCollection *collection))callback
{
    //获取系统相册
    PHAssetCollection *collection = [self getAlbumCollectionWithAlbumId:albumId];
    
    callback(collection);
}

#pragma mark -- 获取相册列表信息

- (void)getImageAlbumList:(void (^)(NSArray *))handler
{
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:0];
    //获取系统相册
    PHFetchResult *smartAlbumsResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    if (smartAlbumsResult != nil){
        
        NSInteger albumCount = smartAlbumsResult.count;
        
        if (albumCount >0 ){
            
            for (int i = 0; i < albumCount; i++){
                
                PHAssetCollection *collection = smartAlbumsResult[i];
                NSString *albumTitle = collection.localizedTitle;
                NSInteger assetSubType = collection.assetCollectionSubtype ;
                
                if (albumTitle == nil){
                    continue;
                }
                
                if([[[UIDevice currentDevice]systemVersion]floatValue] >= 9.0){
                    
                    if(assetSubType == PHAssetCollectionSubtypeSmartAlbumTimelapses ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumSlomoVideos ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumBursts ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumAllHidden ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumVideos ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumPanoramas ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumFavorites ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumSelfPortraits ){
                        continue ;
                    }
                    
                }else{
                    
                    if(assetSubType == PHAssetCollectionSubtypeSmartAlbumTimelapses ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumSlomoVideos ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumBursts ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumAllHidden ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumVideos ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumPanoramas ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumFavorites){
                        continue ;
                    }
                }
                
                NSDictionary *albumDic = [self getAlbumInfoWithPHAssetCollection:collection];
                if (albumDic != nil){
                    if ([[albumDic objectForKey:kGroupLevel] intValue] == 1){
                        [array insertObject:albumDic atIndex:0];
                    }else if ([[albumDic objectForKey:kGroupLevel] intValue] == 2){
                        [array insertObject:albumDic atIndex:1];
                    }else{
                        [array addObject:albumDic];
                    }
                }
            }
        }
    }
    
    //自定义相册
    PHFetchResult *customAlbumsResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    
    if (customAlbumsResult != nil){
        
        NSInteger albumCount = customAlbumsResult.count;
        
        if (albumCount >0 ){
            
            for (int i = 0; i < albumCount ; i++){
                
                PHAssetCollection *collection = customAlbumsResult[i];
                NSString *albumTitle = collection.localizedTitle;
                
                if (albumTitle == nil){
                    continue;
                }
                
                NSDictionary *albumDic = [self getAlbumInfoWithPHAssetCollection:collection];
                if (albumDic != nil){
                    if ([[albumDic objectForKey:kGroupLevel] intValue] == 1){
                        [array insertObject:albumDic atIndex:0];
                    }else if ([[albumDic objectForKey:kGroupLevel] intValue] == 2){
                        [array insertObject:albumDic atIndex:1];
                    }else{
                        [array addObject:albumDic];
                    }
                    
                }
            }
        }
    }
    
    handler(array);
}

#pragma mark -- 相册相关信息

- (NSDictionary *)getAlbumInfoWithPHAssetCollection:(PHAssetCollection *)collection
{
    if (collection == nil){
        return nil;
    }
    
    NSMutableDictionary *albumDic = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    NSString *albumTitle = collection.localizedTitle;
    NSInteger assetSubType = collection.assetCollectionSubtype ;
    
    [albumDic setObject:[NSNumber numberWithInteger:assetSubType] forKey:kGroupSubType];
    
    [albumDic setObject:albumTitle forKey:kGroupTitle];
    [albumDic setObject:[collection.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"] forKey:kGroupId];
    
    PHFetchResult *assetsResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    NSInteger assetsCount = 0;
    if (assetsResult !=nil){
        assetsCount = [assetsResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
    }
    [albumDic setObject:[NSNumber numberWithInteger:assetsCount] forKey:kGroupItemCount];
    
    BOOL isMainAlbum = NO;
    if (assetSubType == PHAssetCollectionSubtypeSmartAlbumUserLibrary){
        isMainAlbum = YES;
        [albumDic setObject:[NSNumber numberWithInt:1] forKey:kGroupLevel];
    }else if (assetSubType == PHAssetCollectionSubtypeAlbumMyPhotoStream){
        [albumDic setObject:[NSNumber numberWithInt:2] forKey:kGroupLevel];
    }else{
        [albumDic setObject:[NSNumber numberWithInt:-1] forKey:kGroupLevel];
    }
    
    [albumDic setObject:[NSNumber numberWithBool:isMainAlbum] forKey:kGroupIsMain];
    
    if (assetSubType == 1000000201 /*最近删除*/){
        [albumDic setObject:[NSNumber numberWithBool:0] forKey:kGroupCanDeleteItem];
        [albumDic setObject:[NSNumber numberWithBool:YES] forKey:kGroupRecentDelete];
    }else{
        BOOL canDeleteItem = [collection canPerformEditOperation:PHCollectionEditOperationDeleteContent];
        [albumDic setObject:[NSNumber numberWithBool:canDeleteItem] forKey:kGroupCanDeleteItem];
        [albumDic setObject:[NSNumber numberWithBool:NO] forKey:kGroupRecentDelete];
    }
    
    //remove content
    BOOL canRemoveItem = [collection canPerformEditOperation:PHCollectionEditOperationRemoveContent];
    [albumDic setObject:[NSNumber numberWithBool:canRemoveItem] forKeyedSubscript:kGroupCanRemoveItem];
    //rename album title
    BOOL canRename = [collection canPerformEditOperation:PHCollectionEditOperationRename];
    [albumDic setObject:[NSNumber numberWithBool:canRename] forKey:kGroupCanRename];
    //add item
    
    if (assetSubType == PHAssetCollectionSubtypeSmartAlbumUserLibrary){
        [albumDic setObject:[NSNumber numberWithBool:1] forKey:kGroupCanAdd];
    }else{
        BOOL canAdd = [collection canPerformEditOperation:PHCollectionEditOperationAddContent];
        [albumDic setObject:[NSNumber numberWithBool:canAdd] forKey:kGroupCanAdd];
    }
    
    //delete album
    BOOL canDelete = [collection canPerformEditOperation:PHCollectionEditOperationDelete];
    [albumDic setObject:[NSNumber numberWithBool:canDelete] forKeyedSubscript:kGroupCanDelete];
    
    return albumDic;
}

- (void)getAlbumInfoWithAlbumId:(NSString *)albumId block:(void(^)(NSDictionary *info))resultHandler
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self getAlbumCollectionWithAlbumId:albumId block:^(PHAssetCollection *collection) {
            NSDictionary *info = [self getAlbumInfoWithPHAssetCollection:collection] ;
            resultHandler(info);
        }];
    });
}

#pragma mark -- 从图片缓存中获取图片

- (void)requestImageFromCacheWithAsset:(PHAsset *)asset
                            targetSize:(CGSize)size
                           contentMode:(PHImageContentMode)contentMode
                               options:(PHImageRequestOptions *)options
                        isNeedDegraded:(BOOL)degraded
                                 block:(void(^)(UIImage *image ,NSDictionary *userInfo))handler
{
    if(!asset){
        handler(nil,nil);
        return ;
    }
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc]init];
    
    [cachingImageManager requestImageForAsset:asset
                                   targetSize:size
                                  contentMode:contentMode
                                      options:options
                                resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info)
     {
         if (degraded == YES){
             
             NSString *identifier = [asset.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"] ;
             
             UIImageOrientation orientation = (UIImageOrientation)[[info objectForKey:@"PHImageFileOrientationKey"] intValue];
             
             NSString *imageName = [[info objectForKey:@"PHImageFileURLKey"]lastPathComponent];
             
             [userInfo setValue:identifier forKey:kLocalIdentifier];
             [userInfo setValue:[NSNumber numberWithInt:orientation] forKey:kItemOrientation];
             [userInfo setValue:imageName forKey:kItemTitle];
             
             handler(result , userInfo);
             
         }else{
             
             //PHImageResultIsDegradedKey  的值为1时，表示为小尺寸的缩略图，此时还在下载原尺寸的图
             BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
             
             if (isDegraded == NO){
                 
                 NSString *identifier = [asset.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"] ;
                 
                 UIImageOrientation orientation = (UIImageOrientation)[[info objectForKey:@"PHImageFileOrientationKey"] intValue];
                 
                 NSString *imageName = [[info objectForKey:@"PHImageFileURLKey"]lastPathComponent];
                 
                 [userInfo setValue:identifier forKey:kLocalIdentifier];
                 [userInfo setValue:[NSNumber numberWithInt:orientation] forKey:kItemOrientation];
                 [userInfo setValue:imageName forKey:kItemTitle];
                 
                 handler(result , userInfo);
             }
             
         }
     }];
}

#pragma mark- 删除或移除照片

- (void)removeImagesWithAlbumID:(NSString *)albumID
            willDeleteImageList:(NSArray *)deleteList
                          block:(void(^)(BOOL suc))handler
{
    PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    
    PHAssetCollection *collection = [self getAlbumCollectionWithAlbumId:albumID];
    
    NSMutableArray *willDeleteList = [[NSMutableArray alloc] initWithCapacity:0];
    
    for (NSDictionary *dic in deleteList){
        
        NSString *path = [dic objectForKey:@"Path"];
        
        NSString *localId = [[[[[path stringByDeletingLastPathComponent] componentsSeparatedByString:@"/"] lastObject] componentsSeparatedByString:@"="] lastObject];
        
        NSString *localIdStr = [localId stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
        PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdStr] options:nil].firstObject;
        
        if(asset){
            [willDeleteList addObject:asset];
        }
        
    }
    
    if([collection canPerformEditOperation:PHCollectionEditOperationDeleteContent]){
        
        //delete
        [photoLibrary performChanges:^{
            
            [PHAssetChangeRequest deleteAssets:willDeleteList];
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            
            if (success){
                handler(nil);
            }else{
                handler(nil);
            }
            
        }];
        
    }else if ([collection canPerformEditOperation:PHCollectionEditOperationRemoveContent]){
        
        //remove
        [photoLibrary performChanges:^{
            
            PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
            [changeRequest removeAssets:willDeleteList];
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            
            if (success){
                handler(nil);
            }else{
                handler(nil);
            }
            
        }];
    }
}

- (void)deleteImageWithAlbumId:(NSString*)albumId
             imageLocalIdArray:(NSArray *)localIdArray
                         block:(void(^)(BOOL suc))handler
{
    PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    
    PHAssetCollection *collection = [self getAlbumCollectionWithAlbumId:albumId];
    
    NSMutableArray *willDeleteList = [[NSMutableArray alloc] initWithCapacity:0];
    
    for (NSString *localId in localIdArray){
        
        NSString *localIdStr = [localId stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
        PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdStr] options:nil].firstObject;
        
        if (asset){
            [willDeleteList addObject:asset];
        }
        
    }
    
    if([collection canPerformEditOperation:PHCollectionEditOperationDeleteContent]){
        
        //delete
        [photoLibrary performChanges:^{
            
            [PHAssetChangeRequest deleteAssets:willDeleteList];
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            
            if(handler){
                handler(success);
            }
            
        }];
        
    }else if ([collection canPerformEditOperation:PHCollectionEditOperationRemoveContent]){
        
        //remove
        [photoLibrary performChanges:^{
            
            PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
            [changeRequest removeAssets:willDeleteList];
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            
            if(handler){
                handler(success);
            }
            
        }];
    }
    
}

- (void)deleteImageWithAlbumId:(NSString*)albumId
                    indexArray:(NSArray*)indexArray
                          sort:(NSComparisonResult)comparison
                         block:(void(^)(bool suc))handler
{
    PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    
    [self getAlbumCollectionWithAlbumId:albumId block:^(PHAssetCollection *collection) {
        
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:(comparison == NSOrderedAscending)?YES:NO]];
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
        PHFetchResult *assetsResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        
        NSMutableArray *willDeleteList = [[NSMutableArray alloc] initWithCapacity:0];
        
        for (NSNumber *indexNumber in indexArray){
            
            NSInteger index = [indexNumber integerValue];
            
            PHAsset *asset = assetsResult[index];
            
            [willDeleteList addObject:asset];
        }
        
        if([collection canPerformEditOperation:PHCollectionEditOperationDeleteContent]){
            
            //delete
            [photoLibrary performChanges:^{
                
                [PHAssetChangeRequest deleteAssets:willDeleteList];
                
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                
                if(handler){
                    handler(success);
                }
                
            }];
            
        }else if ([collection canPerformEditOperation:PHCollectionEditOperationRemoveContent]){
            
            //remove
            [photoLibrary performChanges:^{
                
                PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
                [changeRequest removeAssets:willDeleteList];
                
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                
                if(handler){
                    handler(success);
                }
                
            }];
        }
    }];
}

#pragma mark- 图片添加

- (void)addImageToAlbumWithImage:(UIImage *)image
                         albumId:(NSString *)albumId
                         options:(PHImageRequestOptions *)options
                           block:(void(^)(BOOL suc))block
{
    @autoreleasepool {
        
        __weak typeof(self) weakSelf = self ;
        
        __block NSString *assetId = nil ;
        
        //异步添加相片
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            
            PHAssetCollection *collection = [weakSelf getAlbumCollectionWithAlbumId:albumId];
            PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
            
            PHAssetChangeRequest *changeAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            changeAssetRequest.creationDate = [NSDate date];
            
            PHObjectPlaceholder *assetPlaceholder = [changeAssetRequest placeholderForCreatedAsset];
            
            assetId = assetPlaceholder.localIdentifier ;
            
            if ([collection canPerformEditOperation:PHCollectionEditOperationAddContent]){
                [collectionChangeRequest addAssets:@[assetPlaceholder]];
            }
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            
            if(block){
                block(success);
            }
            
        }];
        
    }
}

- (void)addImageFilesToAlbumWithImages:(NSArray *)imageFiles
                               albumId:(NSString *)albumId
                               options:(PHImageRequestOptions *)options
                                 block:(void(^)(BOOL))block
{
    @autoreleasepool {
        
        __weak typeof(self) weakSelf = self ;
        
        __block NSMutableArray *assetPlaceholderArray = [[NSMutableArray alloc]init];
        
        //异步添加相片
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            
            PHAssetCollection *collection = [weakSelf getAlbumCollectionWithAlbumId:albumId];
            PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
            
            for (NSString *imageFilePath in imageFiles){
                
                UIImage *image = [UIImage imageWithContentsOfFile:imageFilePath];
                
                if (image){
                    
                    PHAssetChangeRequest *changeAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                    changeAssetRequest.creationDate = [NSDate date];
                    if (changeAssetRequest != nil){
                        [assetPlaceholderArray addObject:[changeAssetRequest placeholderForCreatedAsset]];
                    }
                    
                }
            }
            
            if ([collection canPerformEditOperation:PHCollectionEditOperationAddContent]){
                [collectionChangeRequest addAssets:@[assetPlaceholderArray]];
            }
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            
            if(block){
                block(success);
            }
            
        }];
        
    }
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
