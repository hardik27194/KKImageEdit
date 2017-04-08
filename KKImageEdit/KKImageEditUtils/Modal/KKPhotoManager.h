//
//  KKPhotoManager.h
//
//  Created by finger on 16/10/9.
//  Copyright © 2016年 finger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

#define kGroupTitle @"groupTitle"
#define kItems @"items"
#define kLocalIdentifierArray @"localIdentifierArray"
#define kLocalIdentifier @"localIdentifier"
#define kGroupLevel @"groupLevel"
#define kGroupSubType @"groupSubType"
#define kGroupId @"groupId"
#define kGroupItemCount @"groupItemCount"
#define kGroupIsMain @"groupIsMain"
#define kGroupCanDeleteItem @"groupCanDeleteItem"
#define kGroupCanRemoveItem @"groupCanRemoveItem"
#define kGroupRecentDelete @"groupRecentDelete"
#define kGroupCanRename @"groupCanRename"
#define kGroupCanAdd @"groupCanAdd"
#define kGroupCanDelete @"groupCanDelete"
#define kItemOrientation @"itemOrientation"
#define kItemTitle @"itemTitle"
#define kItemCreateDate @"itemCreateDate"
#define kItemModifyDate @"itemModifyDate"
#define kItemWidth @"itemWidth"
#define kItemHeight @"itemHeight"
#define kItemDataSize @"itemDataSize"

#define kNotifyPhotoLibraryDidChange @"photoLibraryDidChange"//相片库发生改变的通知

//用户访问相册权限
typedef NS_ENUM(NSInteger, KKPhotoAuthorizationStatus)
{
    KKPhotoAuthorizationStatusNotDetermined = 0,  // User has not yet made a choice with regards to this application
    
    KKPhotoAuthorizationStatusRestricted,         // This application is not authorized to access photo data.
    // The user cannot change this application’s status, possibly due to active restrictions
    //   such as parental controls being in place.
    KKPhotoAuthorizationStatusDenied,             // User has explicitly denied this            application access to photos data.
    
    KKPhotoAuthorizationStatusAuthorized         // User has authorized this application to access photos data.
};

@interface KKPhotoManager : NSObject

+ (instancetype)shareInstance;

#pragma mark -- 用户权限

- (KKPhotoAuthorizationStatus )convertStatusWithPHAuthorizationStatus:(PHAuthorizationStatus)PHStatus;

- (KKPhotoAuthorizationStatus)authorizationStatus;

- (void)requestAuthorization:(void (^)(KKPhotoAuthorizationStatus))handler;

#pragma mark -- 获取相机胶卷相册的id

- (NSString*)getCameraRollAlbumId;

#pragma mark -- 根据相册的id获取相册的PHFetchResult

- (PHFetchResult *)getAlbumAssetsWithAlbunId:(NSString *)albumId;

#pragma mark -- 获取相片列表

- (void)getAlbumImageWithComparison:(NSComparisonResult)comparison
                           albumObj:(NSObject *)collection
                              block:(void(^)(NSArray *result))handler;

#pragma mark - 图片获取，albumCollection和albumAssets在调用之前必须先初始化

- (void)getThumbnailImageWithIndex:(NSInteger)index
                     needImageSize:(CGSize)size
                    isNeedDegraded:(BOOL)degraded
                              sort:(NSComparisonResult)comparison
                             block:(void(^)(UIImage *image,NSDictionary *userInfo))handler;

- (void)getThumbnailImageWithAlbumAsset:(PHFetchResult *)assetsResult
                                  index:(NSInteger)index
                          needImageSize:(CGSize)size
                         isNeedDegraded:(BOOL)degraded
                                   sort:(NSComparisonResult)comparison
                                  block:(void(^)(UIImage *image,NSDictionary *userInfo))handler;

//TODO:获取全屏显示的照片，注意，在照片的尺寸特别大的情况下，加载原图会导致内存暴增而崩溃(原因不明)，需要重新调整获取图片的大小

- (void)getDisplayImageWithAlbumID:(NSString *)albumID
                             index:(NSInteger)index
                     needImageSize:(CGSize)size
                    isNeedDegraded:(BOOL)degraded
                              sort:(NSComparisonResult)comparison
                             block:(void (^)(UIImage *, NSDictionary *))handler;

#pragma mark -- 根据相册id和图片索引获取图片

- (void)getImageWithAlbumID:(NSString *)albumID
                      index:(NSInteger)index
              needImageSize:(CGSize)size
             isNeedDegraded:(BOOL)degraded
                       sort:(NSComparisonResult)comparison
                      block:(void (^)(UIImage *, NSDictionary *))handler;

#pragma mark -- 根据相册id，图片索引，获取图片数据(NSData)

- (void)getImageDataWithAlbumID:(NSString *)albumID
                          index:(NSInteger)index
                           sort:(NSComparisonResult)comparison
                          block:(void (^)(NSData *, NSDictionary *))handler;

#pragma mark -- 获取相册列表信息

- (void)getImageAlbumList:(void (^)(NSArray *))handler;

#pragma mark -- 相册相关信息

- (NSDictionary *)getAlbumInfoWithPHAssetCollection:(PHAssetCollection *)collection;

- (void)getAlbumInfoWithAlbumId:(NSString *)albumId block:(void(^)(NSDictionary *info))resultHandler;

#pragma mark- 删除或移除照片

- (void)removeImagesWithAlbumID:(NSString *)albumID
            willDeleteImageList:(NSArray *)deleteList
                          block:(void(^)(BOOL suc))handler;

- (void)deleteImageWithAlbumId:(NSString*)albumId
             imageLocalIdArray:(NSArray *)localIdArray
                         block:(void(^)(BOOL suc))handler;

- (void)deleteImageWithAlbumId:(NSString*)albumId
                    indexArray:(NSArray*)indexArray
                          sort:(NSComparisonResult)comparison
                         block:(void(^)(bool suc))handler;

#pragma mark- 图片添加

- (void)addImageToAlbumWithImage:(UIImage *)image
                         albumId:(NSString *)albumId
                         options:(PHImageRequestOptions *)options
                           block:(void(^)(BOOL suc))block;

- (void)addImageFilesToAlbumWithImages:(NSArray *)imageFiles
                               albumId:(NSString *)albumId
                               options:(PHImageRequestOptions *)options
                                 block:(void(^)(BOOL))block;

@end
