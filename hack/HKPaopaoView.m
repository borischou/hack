//
//  HKPaopaoView.m
//  hack
//
//  Created by Zhouboli on 15/7/16.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "HKPaopaoView.h"
#import "UIButton+Bobtn.h"

@implementation HKPaopaoView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initLayoutWithFrame:frame];
    }
    return self;
}

-(void)initLayoutWithFrame:(CGRect)frame
{
    self.layer.cornerRadius = 8;
    self.layer.masksToBounds = YES;
    
    _addrLbl = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, frame.size.width - 10, frame.size.height - 10)];
    _addrLbl.numberOfLines = 1;
    _addrLbl.lineBreakMode = NSLineBreakByWordWrapping;
    _addrLbl.textColor = [UIColor whiteColor];
    _addrLbl.userInteractionEnabled = YES;
    
    [self addSubview:_addrLbl];
}

@end
