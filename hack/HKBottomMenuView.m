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
#define bMenuHeight bHeight/5
#define bBigGap 5
#define bBtnWidth bWidth/5
#define bBtnHeight (bMenuHeight - bBigGap)/2

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
    
    _uberBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, bBtnWidth, bBtnHeight) andTitle:@"UBER" withBackgroundColor:[UIColor redColor] andTintColor:[UIColor whiteColor]];
    [self addSubview:_uberBtn];
    
    _didiBtn = [[UIButton alloc] initWithFrame:CGRectMake(bBtnWidth, 0, bBtnWidth, bBtnHeight) andTitle:@"DiDi" withBackgroundColor:[UIColor greenColor] andTintColor:[UIColor whiteColor]];
    [self addSubview:_didiBtn];
    
    _kuaidiBtn = [[UIButton alloc] initWithFrame:CGRectMake(bBtnWidth*2, 0, bBtnWidth, bBtnHeight) andTitle:@"KuaiDi" withBackgroundColor:[UIColor blueColor] andTintColor:[UIColor whiteColor]];
    [self addSubview:_kuaidiBtn];
    
    _shenzhouBtn = [[UIButton alloc] initWithFrame:CGRectMake(bBtnWidth*3, 0, bBtnWidth, bBtnHeight) andTitle:@"ShenZhou" withBackgroundColor:[UIColor purpleColor] andTintColor:[UIColor whiteColor]];
    [self addSubview:_shenzhouBtn];
    
    _moreBtn = [[UIButton alloc] initWithFrame:CGRectMake(bBtnWidth*4, 0, bBtnWidth, bBtnHeight) andTitle:@"More" withBackgroundColor:[UIColor yellowColor] andTintColor:[UIColor whiteColor]];
    [self addSubview:_moreBtn];
    
    _microphoneBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, bBtnHeight, bBtnWidth, bBtnHeight) andTitle:@"TALK" withBackgroundColor:[UIColor grayColor] andTintColor:[UIColor purpleColor]];
    [self addSubview:_microphoneBtn];
    
    _destLbl = [[UILabel alloc] initWithFrame:CGRectMake(bBtnWidth, bBtnHeight, bBtnWidth*2, bBtnHeight)];
    _destLbl.backgroundColor = [UIColor lightGrayColor];
    _destLbl.textColor = [UIColor whiteColor];
    _destLbl.text = @"Where to?";
    [self addSubview:_destLbl];
    
    _compareBtn = [[UIButton alloc] initWithFrame:CGRectMake(bBtnWidth*3, bBtnHeight, bBtnWidth*2, bBtnHeight) andTitle:@"COMPARE" withBackgroundColor:[UIColor blackColor] andTintColor:[UIColor whiteColor]];
    [self addSubview:_compareBtn];
}

@end
