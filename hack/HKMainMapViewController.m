//
//  HKMainMapViewController.m
//  hack
//
//  Created by Zhouboli on 15/7/15.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import <BaiduMapAPI/BMapKit.h>

#import "HKMainMapViewController.h"
#import "HKAddressTVC.h"
#import "HKPaopaoView.h"
#import "HKBottomMenuView.h"
#import "AppDelegate.h"

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height

#define bMenuHeight bHeight/5
#define bScaleBarHeight 30
#define bFocusBtnHeight 40
#define bPaopaoViewHeight 40

@interface HKMainMapViewController () <BMKMapViewDelegate, BMKLocationServiceDelegate, BMKGeoCodeSearchDelegate, BMKPoiSearchDelegate, HKAddressTVDelegate>

#pragma mark - BaiduMap

@property (strong, nonatomic) BMKMapView *mapView;
@property (strong, nonatomic) BMKPointAnnotation *curAnnotation;
@property (strong, nonatomic) BMKPinAnnotationView *curPinView;
@property (strong, nonatomic) BMKLocationService *locService;
@property (strong, nonatomic) BMKGeoCodeSearch *searcher;
@property (strong, nonatomic) BMKReverseGeoCodeResult *reversedPickupResult;
@property (strong, nonatomic) BMKPoiInfo *userSelectedPoiInfo;

#pragma mark - Custom

@property (copy, nonatomic) NSString *curAddress;

@property (strong, nonatomic) UIImageView *centerPinView;
@property (strong, nonatomic) UIImageView *focusBtnView;

@property (strong, nonatomic) HKPaopaoView *paopaoView;
@property (strong, nonatomic) HKAddressTVC *addressTVC;
@property (strong, nonatomic) HKBottomMenuView *menuView;

@property (nonatomic) CLLocationCoordinate2D destinationCoordinate2D;
@property (nonatomic) CGPoint paopaoCenter;
@property (nonatomic) CGRect mapRect;

@property (nonatomic) BOOL isCenter;
@property (nonatomic) BOOL isCenterMoved;
@property (nonatomic) BOOL isInitLoad;

@end

@implementation HKMainMapViewController

#pragma mark - Lazy boys

-(BMKReverseGeoCodeResult *)reversedPickupResult
{
    if (!_reversedPickupResult) {
        _reversedPickupResult = [[BMKReverseGeoCodeResult alloc] init];
    }
    return _reversedPickupResult;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initBaiduMapView];
    
    [self loadMenuView];
    
    _searcher = [[BMKGeoCodeSearch alloc] init];
    
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

-(void)loadMenuView
{
    _isInitLoad = YES;
    _menuView = [[HKBottomMenuView alloc] init];
    _menuView.userInteractionEnabled = YES;
    [self.view addSubview:_menuView];
    [_menuView.uberBtn addTarget:self action:@selector(carTypeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_menuView.didiBtn addTarget:self action:@selector(carTypeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_menuView.kuaidiBtn addTarget:self action:@selector(carTypeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_menuView.shenzhouBtn addTarget:self action:@selector(carTypeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_menuView.moreBtn addTarget:self action:@selector(carTypeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)loadFloatViews
{
    _centerPinView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    _centerPinView.center = CGPointMake(_mapView.center.x, _mapView.center.y-20);
    _centerPinView.image = [UIImage imageNamed:@"hk_center_2"];
    [self.view addSubview:_centerPinView];
    
    _paopaoView = [[HKPaopaoView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    _paopaoCenter = CGPointMake(_centerPinView.center.x, _centerPinView.center.y - 35);
    _paopaoView.center = _paopaoCenter;
    _paopaoView.backgroundColor = [UIColor purpleColor];
    [self.view addSubview:_paopaoView];
    _paopaoView.addrLbl.text = _curAddress;
    [_paopaoView.addrLbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapLabel:)]];
    
    _focusBtnView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _focusBtnView.frame = CGRectMake(10, bHeight - bMenuHeight - bScaleBarHeight - 10 - bFocusBtnHeight, 40, bFocusBtnHeight);
    _focusBtnView.userInteractionEnabled = YES;
    _focusBtnView.backgroundColor = [UIColor whiteColor];
    _focusBtnView.layer.cornerRadius = 8;
    _focusBtnView.layer.borderWidth = 1;
    _focusBtnView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _focusBtnView.image = [UIImage imageNamed:@"hk_focus_3"];
    [_focusBtnView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFocus:)]];
    [self.view addSubview:_focusBtnView];
}

-(void)detectAvailableCarServices
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!delegate.isLoggedIn) {
        [[[UIAlertView alloc] initWithTitle:@"Login Status" message:@"Please log in first." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Login", nil] show];
    } else {
        //login success
    }
}

-(BOOL)isUberAvailable
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"uber_token"]) {
        return NO;
    } else {
        return YES;
    }
}

-(void)startBaiduLocationService
{
    _locService = [[BMKLocationService alloc] init];
    _locService.delegate = self;
    [_locService startUserLocationService];
}

-(void)initBaiduMapView
{
    _isCenter = NO;
    _mapRect = CGRectMake(0, 0, bWidth, bHeight - bMenuHeight);
    _mapView = [[BMKMapView alloc] initWithFrame:_mapRect];
    [self.view addSubview:_mapView];
    _mapView.showMapScaleBar = YES;
    _mapView.mapScaleBarPosition = CGPointMake(10, bHeight - bMenuHeight - 30);
}

#pragma mark - Button & Gesture callbacks

-(void)carTypeBtnPressed:(UIButton *)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        if ([button.titleLabel.text isEqualToString:@"UBER"]) {
            NSLog(@"UBER");
            if (![self isUberAvailable]) {
                
            }
        }
        if ([button.titleLabel.text isEqualToString:@"滴滴打车"]) {
            NSLog(@"DiDi");
        }
        if ([button.titleLabel.text isEqualToString:@"快的打车"]) {
            NSLog(@"KuaiDi");
        }
        if ([button.titleLabel.text isEqualToString:@"神州专车"]) {
            NSLog(@"ShenZhou");
        }
        if ([button.titleLabel.text isEqualToString:@"更多"]) {
            NSLog(@"More");
        }
    }
}

-(void)tapLabel:(UITapGestureRecognizer *)tap
{
    _addressTVC = [[HKAddressTVC alloc] init];
    _addressTVC.view.backgroundColor = [UIColor whiteColor];
    _addressTVC.pickupResult = _reversedPickupResult;
    _addressTVC.delegate = self;
    
    [self.navigationController pushViewController:_addressTVC animated:YES];
}

-(void)tapFocus:(UITapGestureRecognizer *)tap
{
    [_mapView setCenterCoordinate:_curAnnotation.coordinate animated:YES];
}

#pragma mark - HKAddressTVCDelegate

-(void)userSelectedPoiInfo:(BMKPoiInfo *)info
{
    _userSelectedPoiInfo = info;
    [_mapView setCenterCoordinate:info.pt animated:YES];
}

#pragma mark - BMKGeoCodeSearchDelegate

- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (error == BMK_SEARCH_NO_ERROR) {
        
        _reversedPickupResult = result;
        
        BMKPoiInfo *pickupInfo = [result.poiList firstObject];
        NSString *pickupAddress = pickupInfo.name;
        _paopaoView.addrLbl.text = [NSString stringWithFormat:@"从%@上车", pickupAddress];
        [_paopaoView.addrLbl sizeToFit];
        _paopaoView.frame = CGRectMake(0, 0, _paopaoView.addrLbl.frame.size.width + 10, _paopaoView.addrLbl.frame.size.height + 10);
        _paopaoView.center = _paopaoCenter;
    }
    else
    {
        NSLog(@"error: %u", error);
    }
}

#pragma mark - BMKLocationServiceDelegate

-(void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    _curAnnotation.coordinate = userLocation.location.coordinate;
    if (!_isCenter) {
        BMKMapStatus *status = [[BMKMapStatus alloc] init];
        status.fLevel = 19;
        status.targetGeoPt = _curAnnotation.coordinate;
        [_mapView setMapStatus:status withAnimation:YES withAnimationTime:500];
        _isCenter = YES;
    }
    
    if (_isCenterMoved) {
        CLLocationCoordinate2D centerCoor = [_mapView convertPoint:_centerPinView.center toCoordinateFromView:_mapView];
        BMKReverseGeoCodeOption *reverseGeoCodeOption = [[BMKReverseGeoCodeOption alloc] init];
        reverseGeoCodeOption.reverseGeoPoint = centerCoor;
        BOOL aflag = [_searcher reverseGeoCode:reverseGeoCodeOption];
        if (!aflag) {
            NSLog(@"reverseGeoCode failure, flag = %d", aflag);
        }
        _isCenterMoved = NO;
    }
}

#pragma mark - BMKMapViewDelegate

-(void)mapViewDidFinishLoading:(BMKMapView *)mapView
{
    _isCenterMoved = YES;
}

-(void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (_isInitLoad) {
        [self loadFloatViews];
        _isInitLoad = NO;
    }
    _isCenterMoved = YES;
}

-(BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation
{
    if ([annotation isEqual:_curAnnotation]) {
        _curPinView = [[BMKPinAnnotationView alloc] initWithAnnotation:_curAnnotation reuseIdentifier:@"curAnnotation"];
        _curPinView.pinColor = BMKPinAnnotationColorPurple;
        _curPinView.image = [UIImage imageNamed:@"hk_cur_11"];
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
