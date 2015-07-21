//
//  HKBottomMenuView.m
//  hack
//
//  Created by Zhouboli on 15/7/16.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "HKBottomMenuView.h"
#import "UIButton+Bobtn.h"

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height
#define bMenuHeight bHeight/10
#define bBigGap 5
#define bBtnWidth bWidth/5
#define bBtnHeight (bMenuHeight - 2*bBigGap)

@implementation HKBottomMenuView

-(id)init
{
    self = [super initWithFrame:CGRectMake(0, bHeight - bMenuHeight, bWidth, bMenuHeight)];
    if (self) {
        [self initMenuLayout];
    }
    return self;
}

-(void)initMenuLayout
{
    self.backgroundColor = [UIColor whiteColor];
    
    _compareBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, bBigGap, bBtnWidth, bBtnHeight) andTitle:@"语音" withBackgroundColor:[UIColor grayColor] andTintColor:[UIColor purpleColor]];
    [self addSubview:_compareBtn];
    
    _requestBtn = [[UIButton alloc] initWithFrame:CGRectMake(bBtnWidth*4, bBigGap, bBtnWidth, bBtnHeight) andTitle:@"立即叫车" withBackgroundColor:[UIColor blackColor] andTintColor:[UIColor whiteColor]];
    [self addSubview:_requestBtn];
    
    _destLbl = [[UILabel alloc] initWithFrame:CGRectMake(bBtnWidth, bBigGap, bBtnWidth*3, bBtnHeight)];
    _destLbl.backgroundColor = [UIColor lightGrayColor];
    _destLbl.textColor = [UIColor whiteColor];
    _destLbl.text = @"请输入目的地";
    _destLbl.textAlignment = NSTextAlignmentCenter;
    _destLbl.userInteractionEnabled = YES;
    [self addSubview:_destLbl];
}

@end
