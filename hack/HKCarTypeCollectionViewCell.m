//
//  HKCarTypeCollectionViewCell.m
//  hack
//
//  Created by Zhouboli on 15/7/20.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "HKCarTypeCollectionViewCell.h"

@implementation HKCarTypeCollectionViewCell

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initCellLayout];
    }
    return self;
}

-(void)initCellLayout
{
    self.backgroundColor = [UIColor whiteColor];
    
    _brandTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(3, 3, self.contentView.frame.size.width - 6, (self.contentView.frame.size.height - 3 * 4)/4)];
    _brandTextLabel.textColor = [UIColor lightTextColor];
    _brandTextLabel.backgroundColor = [UIColor redColor];
    [self.contentView addSubview:_brandTextLabel];
    
    _brandIconView = [[UIImageView alloc] initWithFrame:CGRectMake(3, 3 + self.contentView.frame.size.height + 3, self.contentView.frame.size.width - 6, (self.contentView.frame.size.height - 3 * 4)/2)];
    _brandIconView.backgroundColor = [UIColor greenColor];
    [self.contentView addSubview:_brandIconView];
    
    _waitingTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(3, 3*3 + (self.contentView.frame.size.height - 3*4)*3/4, self.contentView.frame.size.width - 6, (self.contentView.frame.size.height - 3 * 4)/4)];
    _waitingTimeLabel.textColor = [UIColor lightTextColor];
    _waitingTimeLabel.backgroundColor = [UIColor blueColor];
}

@end
