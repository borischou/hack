//
//  HKFocusImageView.m
//  hack
//
//  Created by Zhouboli on 15/7/19.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "HKFocusImageView.h"

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height

#define bMenuHeight bHeight/5
#define bScaleBarHeight 30
#define bFocusBtnHeight 40
#define bPaopaoViewHeight 40

@implementation HKFocusImageView

-(id)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(10, bHeight - bMenuHeight - bScaleBarHeight - 10 - bFocusBtnHeight, 40, bFocusBtnHeight);
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 8;
        self.layer.borderWidth = 1;
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.image = [UIImage imageNamed:@"hk_focus_6"];
    }
    return self;
}

@end

