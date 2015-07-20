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
#import "HKCenterPinView.h"
#import "HKFocusView.h"
#import "UberKit.h"

#define uClientId @"VieNQg1vwK3c-bs5Tcl9topkGNvY1eVT"
#define uServerToken @"Qi84DnjRVqadY7adLowTCFJU6Swa_8N-eVMdhzfU"
#define uSecret @"sEWQB8Bj0IWX5Wwdddve4Mr4wK2MsnGzik01ShIi"
#define uAppName @"hack"

#define uAuthUrl @"https://login.uber.com/oauth/authorize"
#define uAccessTokenUrl @"https://login.uber.com/oauth/token"
#define uRedirectUrl @"hack://redirect/auth" //redirect back to Bobo iOS app from Safari website

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

@property (strong, nonatomic) HKPaopaoView *paopaoView;
@property (strong, nonatomic) HKAddressTVC *addressTVC;
@property (strong, nonatomic) HKBottomMenuView *menuView;
@property (strong, nonatomic) HKCenterPinView *centerPinView;
@property (strong, nonatomic) HKFocusView *focusView;

@property (copy, nonatomic) NSString *accessToken;

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
    
    _searcher = [[BMKGeoCodeSearch alloc] init];
    
    [self loadBarbuttonItems];
    [self initBaiduMapView];
    [self loadMenuView];
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

#pragma mark - Uber

-(void)calculateUberEstimatePickupTime:(CLLocationCoordinate2D)pickupCoordinate
{
    UberKit *uberKit = [[UberKit alloc] initWithServerToken:uServerToken];
    CLLocation *pickupLocation = [[CLLocation alloc] initWithLatitude:pickupCoordinate.latitude longitude:pickupCoordinate.longitude];
    [uberKit getTimeForProductArrivalWithLocation:pickupLocation withCompletionHandler:^(NSArray *times, NSURLResponse *response, NSError *error) {
        if(!error)
        {
            if ([times count]) {
                NSMutableArray *estimatedTimes = @[].mutableCopy;
                for (UberTime *time in times) {
                    [estimatedTimes addObject:@(time.estimate)];
                }
                NSSortDescriptor *sortedDescriptor = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:YES];
                NSArray *sortedTimes = [estimatedTimes sortedArrayUsingDescriptors:@[sortedDescriptor]];
  
                NSNumber *soonest = [sortedTimes firstObject];
                [_menuView.uberBtn setTitle:[NSString stringWithFormat:@"%.1fmin", soonest.floatValue/60] forState:UIControlStateNormal];
            }
        }
        else
        {
            NSLog(@"Error %@", error);
        }
    }];
}

#pragma mark - Helpers

-(void)loadBarbuttonItems
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 23, 23)];
    [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileBarButtonPressed)]];
    imageView.userInteractionEnabled = YES;
    imageView.image = [UIImage imageNamed:@"hk_profile_4"];
    UIBarButtonItem *profileBarbutton = [[UIBarButtonItem alloc] initWithCustomView:imageView];
    UIImageView *settingsView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 23, 23)];
    [settingsView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(settingsBarbuttonPressed)]];
    settingsView.userInteractionEnabled = YES;
    settingsView.image = [UIImage imageNamed:@"hk_settings"];
    UIBarButtonItem *settingsBarbutton = [[UIBarButtonItem alloc] initWithCustomView:settingsView];
    
    self.navigationItem.rightBarButtonItem = settingsBarbutton;
    self.navigationItem.leftBarButtonItem = profileBarbutton;
}

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
    [_menuView.destLbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDestinationLabel:)]];
}

-(void)loadFloatViews
{
    _centerPinView = [[HKCenterPinView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    _centerPinView.center = CGPointMake(_mapView.center.x, _mapView.center.y-20);
    [self.view addSubview:_centerPinView];
    
    _paopaoView = [[HKPaopaoView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    _paopaoCenter = CGPointMake(_centerPinView.center.x, _centerPinView.center.y - 35);
    _paopaoView.center = _paopaoCenter;
    _paopaoView.addrLbl.text = _curAddress;
    [_paopaoView.addrLbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapLabel:)]];
    [self.view addSubview:_paopaoView];

    _focusView = [[HKFocusView alloc] initWithFrame:CGRectMake(10, bHeight - bMenuHeight - bScaleBarHeight - 10 - bFocusBtnHeight, 40, bFocusBtnHeight)];
    [_focusView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFocus:)]];
    [self.view addSubview:_focusView];
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

-(void)profileBarButtonPressed
{
    NSLog(@"profileBarButtomPressed");
}

-(void)settingsBarbuttonPressed
{
    NSLog(@"settingsBarbuttonPressed");
}

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

-(void)tapDestinationLabel:(UITapGestureRecognizer *)tap
{
    if (_isCenter) {
        _addressTVC = [[HKAddressTVC alloc] init];
        _addressTVC.view.backgroundColor = [UIColor whiteColor];
        _addressTVC.pickupResult = _reversedPickupResult;
        _addressTVC.delegate = self;
        _addressTVC.searchBar.placeholder = @"您想去哪？";
        _addressTVC.isDestination = YES;
        
        [self.navigationController pushViewController:_addressTVC animated:YES];
    }
}

-(void)tapLabel:(UITapGestureRecognizer *)tap
{
    _addressTVC = [[HKAddressTVC alloc] init];
    _addressTVC.view.backgroundColor = [UIColor whiteColor];
    _addressTVC.pickupResult = _reversedPickupResult;
    _addressTVC.delegate = self;
    _addressTVC.searchBar.placeholder = @"您想从哪上车？";
    _addressTVC.isDestination = NO;
    
    [self.navigationController pushViewController:_addressTVC animated:YES];
}

-(void)tapFocus:(UITapGestureRecognizer *)tap
{
    [_mapView setCenterCoordinate:_curAnnotation.coordinate animated:YES];
}

#pragma mark - HKAddressTVCDelegate

-(void)userSelectedPoiPt:(CLLocationCoordinate2D)pt poiName:(NSString *)name forDestination:(BOOL)isDestination
{
    if (!isDestination) {
        [_mapView setCenterCoordinate:pt animated:YES];
    } else {
        //set the destination label
        _destinationCoordinate2D = pt;
        _menuView.destLbl.text = [NSString stringWithFormat:@"您选择的目的地：%@", name];
    }
}

#pragma mark - BMKGeoCodeSearchDelegate

- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (error == BMK_SEARCH_NO_ERROR) {
        _reversedPickupResult = result;
        
        //Make sure it is the closest BMKPoiInfo in the poiList
        NSMutableDictionary *poiDict = [[NSMutableDictionary alloc] init];
        for (BMKPoiInfo *poiInfo in result.poiList) {
            BMKMapPoint listPt = BMKMapPointForCoordinate(poiInfo.pt);
            BMKMapPoint resultPt = BMKMapPointForCoordinate(result.location);
            CLLocationDistance distance = BMKMetersBetweenMapPoints(listPt, resultPt);
            [poiDict setObject:poiInfo forKey:@(distance)];
        }
        NSArray *distances = [poiDict allKeys];
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:YES];
        NSArray *sortedDistances = [distances sortedArrayUsingDescriptors:@[descriptor]];
        
        NSMutableArray *sortedPoiList = @[].mutableCopy;
        for (NSString *distance in sortedDistances) {
            [sortedPoiList addObject:[poiDict objectForKey:distance]];
        }

        BMKPoiInfo *pickupInfo = [sortedPoiList firstObject];
        NSString *pickupAddress = pickupInfo.name;
        _paopaoView.addrLbl.text = [NSString stringWithFormat:@"从%@上车", pickupAddress];
        [_paopaoView.addrLbl sizeToFit];

        [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:10.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _paopaoView.frame = CGRectMake(0, 0, _paopaoView.addrLbl.frame.size.width + 10, _paopaoView.addrLbl.frame.size.height + 10);
            _paopaoView.center = _paopaoCenter;
        } completion:^(BOOL finished) {
        }];
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
        [self calculateUberEstimatePickupTime:centerCoor];
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
