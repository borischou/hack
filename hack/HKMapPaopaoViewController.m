//
//  HKMapPaopaoViewController.m
//  hack
//
//  Created by Zhouboli on 15/7/15.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "HKMapPaopaoViewController.h"
#import "UIButton+Bobtn.h"

@interface HKMapPaopaoViewController ()

@property (strong, nonatomic) UIButton *testBtn;
@property (strong, nonatomic) UITapGestureRecognizer *tap;

@end

@implementation HKMapPaopaoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    _testBtn = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 100, 20) andTitle:@"TEST" withBackgroundColor:[UIColor greenColor] andTintColor:[UIColor whiteColor]];
    [_testBtn addTarget:self action:@selector(testBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_testBtn];
    
    _addrLbl = [[UILabel alloc] initWithFrame:CGRectMake(5, 30, 150, 100)];
    _addrLbl.lineBreakMode = NSLineBreakByWordWrapping;
    _addrLbl.numberOfLines = 0;
    _addrLbl.backgroundColor = [UIColor blueColor];
    _addrLbl.textColor = [UIColor whiteColor];
    _addrLbl.userInteractionEnabled = YES;
    [self.view addSubview:_addrLbl];
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [_addrLbl addGestureRecognizer:_tap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons

-(void)testBtnPressed:(UIButton *)sender
{
    NSLog(@"test");
    _addrLbl.text = _address;
}

#pragma mark - Gestures

-(void)tapAction:(UITapGestureRecognizer *)tap
{
    NSLog(@"tapped");
    [self.delegate pushToAddressView];
}

@end
