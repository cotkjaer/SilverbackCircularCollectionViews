//
//  SICircularCollectionViewLayout.h
//  SICircularCollectionView
//
//  Created by Christian Otkjær on 04/12/14.
//  Copyright (c) 2014 Christian Otkjær. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SICircularRingCollectionViewLayoutDelegate <NSObject>

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
       rotationForSection:(NSUInteger)section;

- (CGPoint)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
         centerForSection:(NSUInteger)section;

@optional
- (CGPoint)collectionView:(UICollectionView *)collectionView
          centerForLayout:(UICollectionViewLayout *)collectionViewLayout;

- (CGPoint)collectionView:(UICollectionView *)collectionView
      cellRadiusForLayout:(UICollectionViewLayout *)collectionViewLayout;

@end

@interface SICircularRingCollectionViewLayout : UICollectionViewLayout <NSCopying>

@property (nonatomic, assign) CGFloat interCellDistance;
@property (nonatomic, assign) CGSize cellSize;
@property (nonatomic, assign) CGFloat cellRadius;
@property (nonatomic, assign) CGPoint center;

// Radius from section-center to center of cell at indexPath
- (CGFloat)centerRadiusForIndexPath:(NSIndexPath *)indexPath;

// Angle from section-center to center of cell at indexPath
- (CGFloat)centerAngleForIndexPath:(NSIndexPath *)indexPath;

//- (void)prepareNeutralItemIndiciesForCollectionView:(UICollectionView *)collectionView;

@end
