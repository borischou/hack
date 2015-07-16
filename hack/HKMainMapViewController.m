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

@interface HKMainMapViewController () <BMKMapViewDelegate, BMKLocationServiceDelegate, BMKGeoCodeSearchDelegate>

@property (strong, nonatomic) BMKMapView *mapView;

@property (strong, nonatomic) BMKPointAnnotation *curAnnotation;
@property (strong, nonatomic) BMKPinAnnotationView *curPinView;

@property (strong, nonatomic) BMKLocationService *locService;

@property (strong, nonatomic) BMKGeoCodeSearch *searcher;
@property (strong, nonatomic) BMKReverseGeoCodeOption *reverseGeoCodeOption;

@property (copy, nonatomic) NSString *curAddress;

@property (strong, nonatomic) UIImageView *centerPinView;
@property (strong, nonatomic) UIImageView *focusBtnView;

@property (strong, nonatomic) HKPaopaoView *paopaoView;
@property (strong, nonatomic) HKAddressTVC *addressTVC;
@property (strong, nonatomic) HKBottomMenuView *menuView;

@property (strong, nonatomic) CLLocation *startLoc;
@property (strong, nonatomic) CLLocation *destLoc;

@property (copy, nonatomic) NSString *startAddr;
@property (copy, nonatomic) NSString *destAddr;

@property (nonatomic) CGPoint paopaoCenter;
@property (nonatomic) BOOL isCenter;

@end

@implementation HKMainMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initBaiduMapView];
    
    _searcher = [[BMKGeoCodeSearch alloc] init];
    _reverseGeoCodeOption = [[BMKReverseGeoCodeOption alloc] init];
    
    _centerPinView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    _centerPinView.center = _mapView.center;
    _centerPinView.backgroundColor = [UIColor purpleColor];
    [self.view addSubview:_centerPinView];
    
    _paopaoView = [[HKPaopaoView alloc] initWithFrame:CGRectMake(0, 0, bPaopaoViewHeight, bPaopaoViewHeight)];
    _paopaoCenter = CGPointMake(_centerPinView.center.x, _centerPinView.center.y - 40);
    _paopaoView.center = _paopaoCenter;
    _paopaoView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_paopaoView];
    
    _paopaoView.addrLbl.text = _curAddress;
    [_paopaoView.addrLbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(tapLabel:)]];
    
    _focusBtnView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _focusBtnView.frame = CGRectMake(10, bHeight - bMenuHeight - bScaleBarHeight - 10 - bFocusBtnHeight, 40, bFocusBtnHeight);
    _focusBtnView.backgroundColor = [UIColor greenColor];
    _focusBtnView.userInteractionEnabled = YES;
    [_focusBtnView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFocus:)]];
    [self.view addSubview:_focusBtnView];
    
    _menuView = [[HKBottomMenuView alloc] init];
    _menuView.userInteractionEnabled = YES;
    [self.view addSubview:_menuView];
    [_menuView.uberBtn addTarget:self action:@selector(carTypeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_menuView.didiBtn addTarget:self action:@selector(carTypeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_menuView.kuaidiBtn addTarget:self action:@selector(carTypeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_menuView.shenzhouBtn addTarget:self action:@selector(carTypeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_menuView.moreBtn addTarget:self action:@selector(carTypeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
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

-(void)detectAvailableCarServices
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!delegate.isLoggedIn) {
        [[[UIAlertView alloc] initWithTitle:@"Login Status" message:@"Please log in first." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Login", nil] show];
    } else {
        
    }
}

-(BOOL)isUberAvailable
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"uber_token"]) {
        return NO;
    } else return YES;
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
    _mapView = [[BMKMapView alloc] initWithFrame:CGRectMake(0, 0, bWidth, bHeight - bMenuHeight)];
    [self.view addSubview:_mapView];
    _mapView.zoomLevel = 15; //3-19
    _mapView.showMapScaleBar = YES;
    _mapView.mapScaleBarPosition = CGPointMake(10, bHeight - bMenuHeight - 30);
}

-(CGFloat)adjustedWidthForViewWithString:(NSString *)string
{
    CGSize sizeToFit = [string boundingRectWithSize:CGSizeMake(MAXFLOAT, bPaopaoViewHeight) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.f]} context:nil].size;
    return sizeToFit.width;
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
        if ([button.titleLabel.text isEqualToString:@"DiDi"]) {
            NSLog(@"DiDi");
        }
        if ([button.titleLabel.text isEqualToString:@"KuaiDi"]) {
            NSLog(@"KuaiDi");
        }
        if ([button.titleLabel.text isEqualToString:@"ShenZhou"]) {
            NSLog(@"ShenZhou");
        }
        if ([button.titleLabel.text isEqualToString:@"More"]) {
            NSLog(@"More");
        }
    }
}

-(void)tapLabel:(UITapGestureRecognizer *)tap
{
    NSLog(@"label tapped");
    _addressTVC = [[HKAddressTVC alloc] init];
    _addressTVC.title = @"Addresses";
    _addressTVC.view.backgroundColor = [UIColor whiteColor];
    _addressTVC.baseAddress = _startAddr;
    [self.navigationController pushViewController:_addressTVC animated:YES];
}

-(void)tapFocus:(UITapGestureRecognizer *)tap
{
    NSLog(@"center tapped");
    _mapView.centerCoordinate = _curAnnotation.coordinate;
}

-(void)testBtnPressed:(UIButton *)sender
{
    NSLog(@"button pressed");
}

#pragma mark - BMKGeoCodeSearchDelegate

- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (error == BMK_SEARCH_NO_ERROR) {
        _startAddr = result.address;
        
        _paopaoView.addrLbl.text = [NSString stringWithFormat:@"从%@上车..", _startAddr];
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
        _mapView.centerCoordinate = _curAnnotation.coordinate;
        _isCenter = YES;
    }
    
    CLLocationCoordinate2D pickupCoordinate = [_mapView convertPoint:_centerPinView.center toCoordinateFromView:_mapView];
    _reverseGeoCodeOption.reverseGeoPoint = pickupCoordinate;
    _startLoc = [[CLLocation alloc] initWithLatitude:userLocation.location.coordinate.latitude longitude:userLocation.location.coordinate.longitude];
    BOOL flag = [_searcher reverseGeoCode:_reverseGeoCodeOption];
    if (!flag) {
        NSLog(@"reverseGeoCode failure, flag = %d", flag);
    }
}

#pragma mark - BMKMapViewDelegate

-(BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation
{
    if ([annotation isEqual:_curAnnotation]) {

        _curPinView = [[BMKPinAnnotationView alloc] initWithAnnotation:_curAnnotation reuseIdentifier:@"curAnnotation"];
        _curPinView.pinColor = BMKPinAnnotationColorPurple;
        
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
