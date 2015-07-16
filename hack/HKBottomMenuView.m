//
//  HKBottomMenuView.m
//  hack
//
//  Created by Zhouboli on 15/7/16.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "HKBottomMenuView.h"

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height
#define bMenuHeight bHeight/4

@implementation HKBottomMenuView

-(id)init
{
    self = [super initWithFrame:CGRectMake(0, bHeight - bMenuHeight, bWidth, bMenuHeight)];
    if (self) {
        
    }
    return self;
}

@end
