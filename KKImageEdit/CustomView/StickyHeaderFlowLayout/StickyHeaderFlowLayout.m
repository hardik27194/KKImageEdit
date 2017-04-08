//
//  StickyHeaderFlowLayout.m
//  Wombat
//
//  Created by Todd Laney on 1/9/13.
//  Copyright (c) 2013 ToddLa. All rights reserved.
//
//  Modified from http://blog.radi.ws/post/32905838158/sticky-headers-for-uicollectionview-using THANKS!
//

#import "StickyHeaderFlowLayout.h"

@implementation StickyHeaderFlowLayout

- (NSArray *) layoutAttributesForElementsInRect:(CGRect)rect {
    
    NSArray *attributesArray = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray *modifiedAttributesArray = [attributesArray mutableCopy];
    NSMutableIndexSet *attributesToRemoveIdxs = [NSMutableIndexSet indexSet];
    
    NSMutableIndexSet *missingSections = [NSMutableIndexSet indexSet];
    for (NSUInteger idx=0; idx<[attributesArray count]; idx++) {
        UICollectionViewLayoutAttributes *attributes = attributesArray[idx];
        if (attributes.representedElementCategory == UICollectionElementCategoryCell) {
            // remember that we need to layout header for this section
            [missingSections addIndex:attributes.indexPath.section];
        }
        if ([attributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            // remember indexes of header layout attributes, so that we can remove them and add them later
            [attributesToRemoveIdxs addIndex:idx];
        }
    }
    
    // remove headers layout attributes
    [modifiedAttributesArray removeObjectsAtIndexes:attributesToRemoveIdxs];
    
    // layout all headers needed for the rect using self code
    [missingSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:idx];
        UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
        [modifiedAttributesArray addObject:layoutAttributes];
    }];
    
    return modifiedAttributesArray;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    if ([kind isEqualToString:UICollectionElementKindSectionHeader])
    {
        UICollectionView * const cv = self.collectionView;
        /*
         *  初始代码为
         *  CGPoint const contentOffset = cv.contentOffset;
         *  如果是有NavgactionController的情况下，这里需要去掉 "CGPoint const contentOffset = cv.contentOffset;" 中的const,
         *  并添加 "contentOffset.y += 64;" 这段代码，其中64表示是由NavgationBar引起的差值...不同的iPhone尺寸，这里的差值应该不一样
         */
        CGPoint  contentOffset = cv.contentOffset;
//        if navgationbar.translucent == YES,need the offset 64
//        contentOffset.y += 64; //test on iPhone5 is Success
        
        CGPoint nextHeaderOrigin = CGPointMake(INFINITY, INFINITY);
        
        if (indexPath.section+1 < [cv numberOfSections]) {
            UICollectionViewLayoutAttributes *nextHeaderAttributes = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section+1]];
            nextHeaderOrigin = nextHeaderAttributes.frame.origin;
        }
        
        CGRect frame = attributes.frame;
        if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
            frame.origin.y = MIN(MAX(contentOffset.y, frame.origin.y), nextHeaderOrigin.y - CGRectGetHeight(frame));
        }
        else { // UICollectionViewScrollDirectionHorizontal
            frame.origin.x = MIN(MAX(contentOffset.x, frame.origin.x), nextHeaderOrigin.x - CGRectGetWidth(frame));
        }
        attributes.zIndex = 1024;
        attributes.frame = frame;
//        attributes.alpha = 0.9;
        
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    return attributes;
}
- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    return attributes;
}

- (BOOL) shouldInvalidateLayoutForBoundsChange:(CGRect)newBound {
    return YES;
}

@end
