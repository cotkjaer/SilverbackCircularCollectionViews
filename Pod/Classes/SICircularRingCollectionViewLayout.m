//
//  SICircularCollectionViewLayout.m
//  SICircularCollectionView
//
//  Created by Christian Otkjær on 04/12/14.
//  Copyright (c) 2014 Christian Otkjær. All rights reserved.
//

#import "SICircularRingCollectionViewLayout.h"
//#import "easing.h"

@interface SICircularRingCollectionViewLayout ()

//@property (nonatomic, assign) CGFloat innerRadius;

@property (nonatomic, strong) NSMutableArray * radiusBySection; // of NSNumber with CGFloat
@property (nonatomic, strong) NSMutableArray * centerBySection; // of NSValue with CGPoint
@property (nonatomic, strong) NSMutableArray * rotationBySection; // of NSNumber with CGFloat

// arrays to keep track of insert, delete index paths
@property (nonatomic, strong) NSMutableArray * deleteIndexPaths;
@property (nonatomic, strong) NSMutableArray * insertIndexPaths;

@property (nonatomic, weak) id<SICircularRingCollectionViewLayoutDelegate> delegate;

#pragma mark - <UICollectionViewTransitionLayout>
@property (nonatomic, strong) NSArray * fromRotationBySection;
@property (nonatomic, strong) NSArray * toRotationBySection;

@end

@implementation SICircularRingCollectionViewLayout

- (void)setup
{
    _cellSize = CGSizeMake(60.f, 60.f);
    _cellRadius = 30.f;
    _center = CGPointMake(0,0);
    _interCellDistance = 1.f;
    
    _radiusBySection = [NSMutableArray new];
    _rotationBySection = [NSMutableArray new];
    _centerBySection = [NSMutableArray new];

    _deleteIndexPaths = [NSMutableArray array];
    _insertIndexPaths = [NSMutableArray array];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    [self setup];
    
    return self;
}

- (instancetype)init
{
    self = [super init];
    
    [self setup];
    
    return self;
}

#pragma mark - cell size and radius

- (void)setCellRadius:(CGFloat)cellRadius
{
    _cellRadius = cellRadius;
    _cellSize = CGSizeMake(cellRadius * 2.f, cellRadius * 2.f);
}

- (void)setCellSize:(CGSize)cellSize
{
    _cellSize = cellSize;
    _cellRadius = MIN(cellSize.width, cellSize.height) / 2.f;
}

#pragma mark - Radius

- (CGFloat)defaultRadiusForSection:(NSUInteger)section
{
    return section * (2 * self.cellRadius + self.interCellDistance);
}

- (CGFloat)radiusForSection:(NSUInteger)section
{
    if (section < self.radiusBySection.count)
    {
        return [self.radiusBySection[section] floatValue];
    }
    else
    {
        return 0.f;
    }
}

- (void)setRadius:(CGFloat)radius forSection:(NSUInteger)section
{
    if (section <= self.radiusBySection.count)
    {
        self.radiusBySection[section] = @(radius);
    }
}

- (CGFloat)distanceBetween:(CGPoint)p1 and:(CGPoint)p2
{
    return sqrtf(powf(p2.x-p1.x,2)+powf(p2.y-p1.y,2));
}

// http://math.stackexchange.com/questions/278642/Ноw-many-equal-circles-can-be-placed-around-a-circle
// NB! must be called after the centers have been updated
- (void)updateRadiForSectionsForCollectionView:(UICollectionView *)collectionView
{
    __block CGFloat radius = 0.f;
    __block CGPoint previousCenter;
    
    CGFloat paddedCellRadius = self.cellRadius + self.interCellDistance;

    [self enumerateSectionsForCollectionView:collectionView
                                  usingBlock:^(NSUInteger section, BOOL *stop)
     {
         CGPoint center = [self centerForSection:section];
         
         NSUInteger numberOfItems = [collectionView numberOfItemsInSection:section];
         
         if (section == 0)
         {
             if (numberOfItems == 1)
             {
                     radius = 0.f;
             }
             else
             {
                 CGFloat phi = M_TWO_PI / numberOfItems;
                 radius = paddedCellRadius / sinf(phi/2.f);
             }
         }
         else
         {
             CGFloat minRadius = radius + self.cellSize.height + self.interCellDistance;
             
             if (!CGPointEqualToPoint(center, previousCenter))
             {
                 minRadius += [self distanceBetween:center and:previousCenter];
             }
             
             CGFloat phi = M_TWO_PI / numberOfItems;
             CGFloat neededRadius = paddedCellRadius / sinf(phi/2.f);
             
             radius = MAX(minRadius, neededRadius);
         }
         
         [self setRadius:radius forSection:section];
         
         previousCenter = center;
     }];
}


#pragma mark - Rotation

- (CGFloat)defaultRotationForSection:(NSUInteger)section
{
    return 0.f;
}

- (CGFloat)rotationForSection:(NSUInteger)section
{
    if (section < self.rotationBySection.count)
    {
        return [self.rotationBySection[section] floatValue];
    }
    else
    {
        return 0.f;
    }
}

- (void)setRotation:(CGFloat)rotation forSection:(NSUInteger)section
{
    if (section <= self.rotationBySection.count)
    {
        self.rotationBySection[section] = @(rotation);
    }
}

- (void)updateRotationsForSectionsForCollectionView:(UICollectionView *)collectionView
{
    BOOL askDelegate = [self.delegate respondsToSelector:@selector(collectionView:layout:rotationForSection:)];
    
    [self enumerateSectionsForCollectionView:collectionView
                                  usingBlock:^(NSUInteger section, BOOL *stop)
     {
         [self setRotation:askDelegate ? [self.delegate collectionView:collectionView layout:self rotationForSection:section] : [self defaultRotationForSection:section] forSection:section];
     }];
}

//- (void)prepareRotationsForCollectionView:(UICollectionView *)collectionView
//{
//    [self.rotationBySection removeAllObjects];
//    
//    if ([self.nextLayout isKindOfClass:[SICircularCollectionViewLayout class]] &&
//        [self.currentLayout isKindOfClass:[SICircularCollectionViewLayout class]])
//    {
//        CGFloat progress = ElasticEaseInOut(self.transitionProgress);
//        
//        //        SICircularCollectionViewLayout * fromLayout = (SICircularCollectionViewLayout *)self.currentLayout;
//        //        SICircularCollectionViewLayout * toLayout = (SICircularCollectionViewLayout *)self.nextLayout;
//        
//        [self enumerateSectionsForCollectionView:collectionView
//                                      usingBlock:^(NSUInteger section, BOOL *stop)
//         {
//             CGFloat fromIndex = [self.fromRotationBySection[section] floatValue];//[fromLayout rotationForSection:section];
//             CGFloat toIndex = [self.toRotationBySection[section] floatValue];//[toLayout rotationForSection:section];
//             
//             CGFloat currentIndex = fromIndex + ((toIndex - fromIndex) * progress);
//             
//             [self setRotation:currentIndex forSection:section];
//         }];
//    }
//    else
//    {
//        [self enumerateSectionsForCollectionView:collectionView
//                                      usingBlock:^(NSUInteger section, BOOL *stop)
//         {
//             self.rotationBySection[section] = @((float)([collectionView numberOfItemsInSection:section] - 1) / 2.f);
//         }];
//        
//        [collectionView.indexPathsForSelectedItems enumerateObjectsUsingBlock:^(NSIndexPath * selectedPath, NSUInteger idx, BOOL *stop)
//         {
//             self.rotationBySection[selectedPath.section] = @(selectedPath.item);
//         }];
//    }
//}


- (void)enumerateSectionsForCollectionView:(UICollectionView *)collectionView
                                usingBlock:(void (^)(NSUInteger section, BOOL *stop))block
{
    BOOL stop = NO;
    
    NSUInteger numberOfSections = [collectionView numberOfSections];
    
    for (NSUInteger section = 0; section < numberOfSections; section++)
    {
        block(section, &stop);
        
        if (stop) break;
    }
}

- (void)enumerateSectionsUsingBlock:(void (^)(NSUInteger section, BOOL *stop))block
{
    [self enumerateSectionsForCollectionView:self.collectionView
                                  usingBlock:block];
}

- (void)enumerateIndexPathsUsingBlock:(void (^)(NSIndexPath * path, BOOL *stop))block
{
    [self enumerateSectionsUsingBlock:^(NSUInteger section, BOOL *stop)
     {
         NSUInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
         
         for (NSUInteger item = 0; item < numberOfItems; item++)
         {
             block([NSIndexPath indexPathForItem:item inSection:section], stop);
             
             if (*stop) break;
         }
     }];
}

- (CGSize)collectionViewContentSize
{
    __block CGRect frame = CGRectMake(self.center.x, self.center.y, 0, 0);
    
    [self enumerateIndexPathsUsingBlock:^(NSIndexPath *path, BOOL *stop)
     {
         frame = CGRectUnion(frame, [self frameForItemAtIndexPath:path]);
         
     }];
    
    return frame.size;
}

- (void)updateDelegate
{
    if ([self.collectionView.delegate conformsToProtocol:@protocol(SICircularRingCollectionViewLayoutDelegate)])
    {
        self.delegate = (id<SICircularRingCollectionViewLayoutDelegate>)self.collectionView.delegate;
    }
    else
    {
        self.delegate = nil;
    }
}

#pragma mark - Centers for Sections

- (CGPoint)centerForSection:(NSUInteger)section
{
    if (section < self.centerBySection.count)
    {
        return [self.centerBySection[section] CGPointValue];
    }
    else
    {
        return self.center;
    }
}

- (void)setCenter:(CGPoint)center forSection:(NSUInteger)section
{
    if (self.centerBySection.count >= section)
    {
        self.centerBySection[section] = [NSValue valueWithCGPoint:center];
    }
}

- (void)updateCentersForSectionsForCollectionView:(UICollectionView *)collectionView
{
    [self.centerBySection removeAllObjects];
    
    [self enumerateSectionsForCollectionView:collectionView usingBlock:^(NSUInteger section, BOOL *stop)
     {
         if ([self.delegate respondsToSelector:@selector(collectionView:layout:centerForSection:)])
         {
             [self setCenter:[self.delegate collectionView:collectionView layout:self centerForSection:section] forSection:section];
         }
         else
         {
             [self setCenter:self.center forSection:section];
         }
     }];
}

-(void)prepareLayout
{
    [super prepareLayout];
    
    [self updateDelegate];
    
    [self updateRotationsForSectionsForCollectionView:self.collectionView];
    
    [self updateCentersForSectionsForCollectionView:self.collectionView];
    
    [self updateRadiForSectionsForCollectionView:self.collectionView];
    
//    NSUInteger innerCellCount =  [self.collectionView numberOfItemsInSection:0];
    
//    if (innerCellCount > 0)
//    {
//        self.innerRadius = self.cellSize.height * innerCellCount / (2.f * M_PI);
//    }
}

- (CGRect)frameForItemAtIndexPath:(NSIndexPath *)path
{
    CGPoint center = [self centerForItemAtIndexPath:path];
    CGSize size = [self sizeForItemAtIndexPath:path];
    
    return CGRectMake(center.x - size.width / 2.f,
                      center.y - size.height / 2.f,
                      size.width,
                      size.height);
}

- (CGFloat)centerRadiusForIndexPath:(NSIndexPath *)path
{
    return [self radiusForSection:path.section];//self.innerRadius + self.cellRadius * path.section;
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)path
{
    return self.cellSize;
}

CGFloat const M_TWO_PI = M_PI * 2.f;
/*
 static CGFloat normalizeAngle(CGFloat angle)
 {
 while (angle < 0)
 {
 angle += M_TWO_PI;
 }
 
 while (angle > M_TWO_PI)
 {
 angle -= M_TWO_PI;
 }
 
 return angle;
 }
 */

- (CGFloat)centerAngleForIndexPath:(NSIndexPath *)path
{
    CGFloat radius = [self centerRadiusForIndexPath:path];
    
    if (radius < 0.01f)
    {
        return 0;
    }
    
    CGFloat deltaAngle = (self.cellSize.height + self.interCellDistance) / radius; // TODO: traverse items before in section and add up their angles
    
    NSInteger count = path.item;
    
    CGFloat rotationForSection = [self rotationForSection:path.section];
    
    return (count * deltaAngle) - rotationForSection;
}

- (CGPoint)centerForItemAtIndexPath:(NSIndexPath *)path
{
    CGFloat rotationForIndexPath = [self centerAngleForIndexPath:path];
    
    CGFloat radius = [self centerRadiusForIndexPath:path];
    
    CGPoint center = [self centerForSection:path.section];
    
    center = CGPointMake(center.x + radius * cosf(rotationForIndexPath),
                       center.y + radius * sinf(rotationForIndexPath));
    
    return center;
}

- (void)invalidateLayout
{
    NSLog(@"%@.%@",NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    [self.centerBySection removeAllObjects];
    [self.rotationBySection removeAllObjects];
    
    [super invalidateLayout];
}

- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context
{
    NSLog(@"%@.%@",NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    [super invalidateLayoutWithContext:context];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)path
{
    NSLog(@"%@%ld - %ld", NSStringFromSelector(_cmd), (long)path.section, (long)path.item);
    
    UICollectionViewLayoutAttributes * attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:path];
    
    attributes.frame = [self frameForItemAtIndexPath:path];
//    attributes.alpha = 1.0;
    
    return attributes;
}

-(NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSLog(@"%@.%@%@",NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromCGRect(rect));
    
    NSMutableArray * attributes = [NSMutableArray array];
    
    [self enumerateIndexPathsUsingBlock:^(NSIndexPath *path, BOOL *stop)
     {
         UICollectionViewLayoutAttributes * itemAttributes = [self layoutAttributesForItemAtIndexPath:path];
         
                 if (CGRectIntersectsRect(rect, itemAttributes.frame))
                 {
         [attributes addObject:itemAttributes];
                 }
     }];
    
    return [attributes copy];
}

- (void)prepareForAnimatedBoundsChange:(CGRect)oldBounds
{
    [super prepareForAnimatedBoundsChange:oldBounds];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return !CGSizeEqualToSize(self.collectionView.bounds.size, newBounds.size);
}

#pragma mark - UICollectionViewUpdates

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
    // Keep track of insert and delete index paths
    [super prepareForCollectionViewUpdates:updateItems];
    
    //    [self.deleteIndexPaths removeAllObjects];//= [NSMutableArray array];
    //    [self.insertIndexPaths removeAllObjects];//= [NSMutableArray array];
    
    [updateItems enumerateObjectsUsingBlock:^(UICollectionViewUpdateItem * update, NSUInteger idx, BOOL *stop)
     {
         switch (update.updateAction)
         {
             case UICollectionUpdateActionDelete:
                 [self.deleteIndexPaths addObject:update.indexPathBeforeUpdate];
                 break;
                 
             case UICollectionUpdateActionInsert:
                 [self.insertIndexPaths addObject:update.indexPathAfterUpdate];
                 break;
                 
             default:
                 break;
         }
     }];
}

- (void)finalizeCollectionViewUpdates
{
    [super finalizeCollectionViewUpdates];
    // release the insert and delete index paths
    //    self.deleteIndexPaths = nil;
    //    self.insertIndexPaths = nil;
    [self.deleteIndexPaths removeAllObjects];//= [NSMutableArray array];
    [self.insertIndexPaths removeAllObjects];//= [NSMutableArray array];
}

// NB! Also this gets called for all visible cells (not just the inserted ones) and even gets called when deleting cells!
- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    // Must call super
    UICollectionViewLayoutAttributes * attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    
    if ([self.insertIndexPaths containsObject:itemIndexPath])
    {
        if (!attributes)
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        
        // Configure attributes ...
        attributes.alpha = 0.0;
    }
    
    return attributes;
}

// NB Also this gets called for all visible cells (not just the deleted ones) and even gets called when inserting cells!
- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    // So far, calling super hasn't been strictly necessary here, but leaving it in
    // for good measure
    UICollectionViewLayoutAttributes * attributes = [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    
    if ([self.deleteIndexPaths containsObject:itemIndexPath])
    {
        if (!attributes)
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        
        // Configure attributes ...
        attributes.alpha = 0.0;
        attributes.transform = CGAffineTransformMakeScale(0.1, 0.1);
    }
    
    return attributes;
}

//#pragma mark - <UICollectionViewTransitionLayout>
//
//- (instancetype)initWithCurrentLayout:(UICollectionViewLayout *)currentLayout
//                           nextLayout:(UICollectionViewLayout *)newLayout
//{
//    if ([currentLayout isKindOfClass:[SICircularCollectionViewLayout class]] &&
//        [newLayout isKindOfClass:[SICircularCollectionViewLayout class]])
//    {
//        self = [super initWithCurrentLayout:currentLayout nextLayout:newLayout];
//        
//        if (self)
//        {
//            [self setup];
//            _toRotationBySection = [[(SICircularCollectionViewLayout *)newLayout rotationBySection] copy];
//            _fromRotationBySection = [[(SICircularCollectionViewLayout *)currentLayout rotationBySection] copy];
//        }
//        
//        return self;
//    }
//    
//    return nil;
//}
//
//- (void)setTransitionProgress:(CGFloat)transitionProgress
//{
//    //    NSLog(@"Set Progress %@", @(transitionProgress));
//    [super setTransitionProgress:transitionProgress];
//}
//
//- (CGFloat)transitionProgress
//{
//    //    NSLog(@"Get Progress %@", @([super transitionProgress]));
//    return [super transitionProgress];
//}
//
//- (void)updateValue:(CGFloat)value forAnimatedKey:(NSString *)key
//{
//    NSLog(@"updateValue:%@ forAnimatedKey:%@", @(value), key);
//    
//    [super updateValue:value forAnimatedKey:key];
//}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    SICircularRingCollectionViewLayout * layoutCopy = [SICircularRingCollectionViewLayout new];
    
    layoutCopy.cellSize = self.cellSize;
    layoutCopy.center = self.center;
    
    layoutCopy.deleteIndexPaths = [self.deleteIndexPaths mutableCopy];
    layoutCopy.insertIndexPaths = [self.insertIndexPaths mutableCopy];
    
    layoutCopy.rotationBySection = [self.rotationBySection mutableCopy];
    
    layoutCopy.centerBySection = [self.centerBySection mutableCopy];
    
    return layoutCopy;
}

@end
