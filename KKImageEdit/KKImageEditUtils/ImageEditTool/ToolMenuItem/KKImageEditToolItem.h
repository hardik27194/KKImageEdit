//
//  ImageEditToolItem.h
//  
//
//  Created by finger on 17/2/13.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKImageEditHeader.h"

@protocol KKImageEditToolItemDelegate;

@interface KKImageEditToolItem : UIView

@property(nonatomic)NSDictionary *editInfo;
@property(nonatomic,assign)KKImageEditType editType;
@property(nonatomic)NSString *itemTitle;
@property(nonatomic)UIImage *itemImage ;
@property(nonatomic)id<KKImageEditToolItemDelegate>delegate ;
@property(nonatomic)BOOL selected ;
@property(nonatomic)BOOL hideTitle ;

@property(nonatomic)UILabel *titleLabel ;
@property(nonatomic)UIImageView *itemImageView;

@end

@protocol KKImageEditToolItemDelegate <NSObject>
- (void)imageEditItem:(KKImageEditToolItem *)item clickItemWithType:(KKImageEditType)editType editInfo:(NSDictionary *)editInfo;
@end
