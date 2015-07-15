//
//  HKMainMapViewController.m
//  hack
//
//  Created by Zhouboli on 15/7/15.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import <BaiduMapAPI/BMapKit.h>

#import "HKMainMapViewController.h"
#import "HKMapPaopaoViewController.h"
#import "HKAddressTVC.h"

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height

#define bTabbarHeight 100
#define bScaleBarHeight 30
#define bFocusBtnHeight 40

@interface HKMainMapViewController () <BMKMapViewDelegate, BMKLocationServiceDelegate, BMKGeoCodeSearchDelegate, HKMapPaopaoViewDelegate>

@property (strong, nonatomic) BMKMapView *mapView;

@property (strong, nonatomic) BMKPointAnnotation *curAnnotation;
@property (strong, nonatomic) BMKPinAnnotationView *curPinView;

@property (strong, nonatomic) BMKLocationService *locService;

@property (strong, nonatomic) BMKGeoCodeSearch *searcher;
@property (strong, nonatomic) BMKReverseGeoCodeOption *reverseGeoCodeOption;

@property (copy, nonatomic) NSString *curAddress;

@property (strong, nonatomic) UIImageView *centerPinView;
@property (strong, nonatomic) UIImageView *focusBtnView;

@property (strong, nonatomic) HKAddressTVC *addressTVC;
@property (strong, nonatomic) HKMapPaopaoViewController *paopaoVC;

@end

@implementation HKMainMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initBaiduMapView];
    
    _searcher = [[BMKGeoCodeSearch alloc] init];
    _reverseGeoCodeOption = [[BMKReverseGeoCodeOption alloc] init];
    
    _centerPinView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    _centerPinView.center = self.view.center;
    _centerPinView.backgroundColor = [UIColor purpleColor];
    [self.view addSubview:_centerPinView];
    
    _focusBtnView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _focusBtnView.frame = CGRectMake(10, bHeight - bTabbarHeight - bScaleBarHeight - 10 - bFocusBtnHeight, 40, bFocusBtnHeight);
    _focusBtnView.backgroundColor = [UIColor greenColor];
    _focusBtnView.userInteractionEnabled = YES;
    [_focusBtnView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFocus:)]];
    [self.view addSubview:_focusBtnView];
    
    [self startBaiduLocationService];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _mapView.delegate = self;
    _searcher.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_curAnnotation != nil) {
        [_mapView removeAnnotation:_curAnnotation];
    }
    
    _mapView.delegate = nil;
    _searcher.delegate = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _curAnnotation = [[BMKPointAnnotation alloc] init];
    [_mapView addAnnotation:_curAnnotation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Helpers

-(void)tapFocus:(UITapGestureRecognizer *)tap
{
    NSLog(@"center tapped");
    _mapView.centerCoordinate = _curAnnotation.coordinate;
}

-(void)startBaiduLocationService
{
    _locService = [[BMKLocationService alloc] init];
    _locService.delegate = self;
    [_locService startUserLocationService];
}

-(void)initBaiduMapView
{
    _mapView = [[BMKMapView alloc] initWithFrame:CGRectMake(0, 0, bWidth, bHeight)];
    [self.view addSubview:_mapView];
    _mapView.zoomLevel = 15; //3-19`
    _mapView.showMapScaleBar = YES;
    _mapView.mapScaleBarPosition = CGPointMake(10, bHeight - bTabbarHeight - 30);
}


#pragma mark - HKMapPaopaoViewDelegate

-(void)pushToAddressView
{
    _addressTVC = [[HKAddressTVC alloc] initWithStyle:UITableViewStylePlain];
    _addressTVC.title = @"Addresses";
    _addressTVC.tableView.backgroundColor = [UIColor whiteColor];
    [self.navigationController pushViewController:_addressTVC animated:YES];
}

#pragma mark - BMKGeoCodeSearchDelegate

- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (error == BMK_SEARCH_NO_ERROR) {
        _curAddress = result.address;
        _paopaoVC.address = _curAddress;
    } else
    {
        NSLog(@"error: %u", error);
    }
}

#pragma mark - BMKLocationServiceDelegate

-(void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    _curAnnotation.coordinate = userLocation.location.coordinate;
    _reverseGeoCodeOption.reverseGeoPoint = _curAnnotation.coordinate;
    BOOL flag = [_searcher reverseGeoCode:_reverseGeoCodeOption];
    if (!flag) {
        NSLog(@"reverseGeoCode failure, flag = %d", flag);
    }
}

#pragma mark - BMKMapViewDelegate

-(BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation
{
    if ([annotation isEqual:_curAnnotation]) {
        _paopaoVC = [[HKMapPaopaoViewController alloc] init];
        _paopaoVC.view.frame = CGRectMake(0, 0, 200, 200);
        _paopaoVC.delegate = self;
        if (!_curAddress) {
            _paopaoVC.addrLbl.text = @"Loading...";
        } else {
            _paopaoVC.addrLbl.text = _curAddress;
        }
        _curPinView = [[BMKPinAnnotationView alloc] initWithAnnotation:_curAnnotation reuseIdentifier:@"curAnnotation"];
        _curPinView.pinColor = BMKPinAnnotationColorPurple;
        _curPinView.paopaoView = [[BMKActionPaopaoView alloc] initWithCustomView:_paopaoVC.view];
        [_curPinView setSelected:YES animated:YES];
        
        return _curPinView;
    }
    
    return nil;
}

-(void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view
{
    if ([view isEqual:_curPinView]) {
        mapView.centerCoordinate = view.annotation.coordinate;
    }
}


@end
