//
//  HKAddressTVC.m
//  hack
//
//  Created by Zhouboli on 15/7/15.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "HKAddressTVC.h"
#import <BaiduMapAPI/BMapKit.h>

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height
#define bTableViewHeight bHeight/2
#define bMapViewHeight bHeight - bTableViewHeight

@interface HKAddressTVC () <UITableViewDataSource, UITableViewDelegate, BMKMapViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) BMKMapView *mapView;

@end

@implementation HKAddressTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _mapView = [[BMKMapView alloc] initWithFrame:CGRectMake(0, 0, bWidth, bMapViewHeight)];
    [self.view addSubview:_mapView];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, bHeight/2, bWidth, bTableViewHeight) style:UITableViewStylePlain];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _mapView.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _mapView.delegate = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_pickupResult.poiList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"reuse"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuse" forIndexPath:indexPath];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    BMKPoiInfo *poiInfo = [_pickupResult.poiList objectAtIndex:indexPath.row];
    if (0 == indexPath.row) {
        cell.textLabel.text = [NSString stringWithFormat:@"当前: %@", poiInfo.name];
        cell.textLabel.textColor = [UIColor blueColor];
    } else {
        cell.textLabel.text = poiInfo.name;
    }
    
    return cell;
}

@end
