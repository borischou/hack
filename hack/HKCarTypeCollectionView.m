//
//  HKCarTypeCollectionView.m
//  hack
//
//  Created by Zhouboli on 15/7/20.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "HKCarTypeCollectionView.h"
#import "HKCarTypeCollectionViewCell.h"

@interface HKCarTypeCollectionView () <UICollectionViewDataSource>

@end

@implementation HKCarTypeCollectionView

-(id)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self initCollectionViewLayout:layout];
    }
    return self;
}

-(void)initCollectionViewLayout:(UICollectionViewLayout *)layout
{
    self.backgroundColor = [UIColor purpleColor];
    [self registerClass:[HKCarTypeCollectionViewCell class] forCellWithReuseIdentifier:@"reuseCell"];
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)layout;
    flowLayout.itemSize = CGSizeMake(self.frame.size.width/4, self.frame.size.height);
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 0;
}

#pragma mark - UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 4;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HKCarTypeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"reuseCell" forIndexPath:indexPath];
    
    return cell;
}

@end
