//
//  HKDetailViewController.m
//  hack
//
//  Created by Zhouboli on 15/7/21.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "HKDetailViewController.h"
#import "UIButton+Bobtn.h"
#import "UberKit.h"

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height

@interface HKDetailViewController ()

@property (strong, nonatomic) UILabel *startAddressLabel;
@property (strong, nonatomic) UILabel *destAddressLabel;
@property (strong, nonatomic) UIButton *confirmButton;

@end

@implementation HKDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"确认页";
    _startAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, bHeight/4, bWidth-100, bHeight/10)];
    _startAddressLabel.textColor = [UIColor blackColor];
    [self.view addSubview:_startAddressLabel];
    
    _destAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, bHeight/2, bWidth-100, bHeight/10)];
    _destAddressLabel.textColor = [UIColor blackColor];
    [self.view addSubview:_destAddressLabel];
    
    _confirmButton = [[UIButton alloc] initWithFrame:CGRectMake(50, bHeight*3/4, bWidth-100, bHeight/10) andTitle:@"确认打车" withBackgroundColor:[UIColor blueColor] andTintColor:[UIColor whiteColor]];
    [_confirmButton addTarget:self action:@selector(confirmButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_confirmButton];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _startAddressLabel.text = [NSString stringWithFormat:@"上车：%@ %@", [_startLocation[@"start_array"] firstObject], [_startLocation[@"start_array"] objectAtIndex:1]];
    _destAddressLabel.text = [NSString stringWithFormat:@"目的地：%@ %@", [_destLocation[@"dest_array"] firstObject],[_destLocation[@"dest_array"] objectAtIndex:1]];
}

#pragma mark - UIButtons

-(void)confirmButtonPressed:(UIButton *)sender
{
    
}

@end
