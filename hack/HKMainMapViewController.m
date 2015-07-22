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
#import "HKCarTypeCollectionView.h"
#import "HKCarTypeCollectionViewCell.h"
#import "HKDetailViewController.h"

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

@interface HKMainMapViewController () <UberKitDelegate, BMKMapViewDelegate, BMKLocationServiceDelegate, BMKGeoCodeSearchDelegate, BMKPoiSearchDelegate, HKAddressTVDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIAlertViewDelegate>

#pragma mark - BaiduMap

@property (strong, nonatomic) BMKMapView *mapView;
@property (strong, nonatomic) BMKPointAnnotation *curAnnotation;
@property (strong, nonatomic) BMKPinAnnotationView *curPinView;
@property (strong, nonatomic) BMKLocationService *locService;
@property (strong, nonatomic) BMKGeoCodeSearch *searcher;
@property (strong, nonatomic) BMKGeoCodeSearch *searcherForDestination;
@property (strong, nonatomic) BMKReverseGeoCodeResult *reversedPickupResult;
@property (strong, nonatomic) BMKPoiInfo *userSelectedPoiInfo;

@property (strong, nonatomic) UberTime *estimateTime;
@property (strong, nonatomic) UberProfile *profile;

#pragma mark - Custom

@property (copy, nonatomic) NSString *curAddress;

@property (strong, nonatomic) HKPaopaoView *paopaoView;
@property (strong, nonatomic) HKAddressTVC *addressTVC;
@property (strong, nonatomic) HKBottomMenuView *menuView;
@property (strong, nonatomic) HKCenterPinView *centerPinView;
@property (strong, nonatomic) HKFocusView *focusView;
@property (strong, nonatomic) HKCarTypeCollectionView *carTypeCollectionView;

@property (copy, nonatomic) NSString *accessToken;
@property (copy, nonatomic) NSString *uberWaitingMins;
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) NSMutableDictionary *startLocation;
@property (strong, nonatomic) NSMutableDictionary *destLocation;

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

-(NSMutableDictionary *)startLocation
{
    if (!_startLocation) {
        _startLocation = @{}.mutableCopy;
    }
    return _startLocation;
}

-(NSMutableDictionary *)destLocation
{
    if (!_destLocation) {
        _destLocation = @{}.mutableCopy;
    }
    return _destLocation;
}

-(UberProfile *)profile
{
    if (!_profile) {
        _profile = [[UberProfile alloc] init];
    }
    return _profile;
}

-(UberTime *)estimateTime
{
    if (!_estimateTime) {
        _estimateTime = [[UberTime alloc] init];
    }
    return _estimateTime;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"打车神器(内测版)";
    
    _searcher = [[BMKGeoCodeSearch alloc] init];
    _searcherForDestination = [[BMKGeoCodeSearch alloc] init];
    
    [self loadBarbuttonItems];
    [self initBaiduMapView];
    [self loadMenuView];
    [self loadCollectionView];
    [self startBaiduLocationService];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"uber token: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"uber_token"]);
    
    _mapView.delegate = self;
    _searcher.delegate = self;
    _searcherForDestination.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_curAnnotation != nil) {
        [_mapView removeAnnotation:_curAnnotation];
    }
    
    _mapView.delegate = nil;
    _searcher.delegate = nil;
    _searcherForDestination.delegate = nil;
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

-(void)uberRequestProfile
{
    [[UberKit sharedInstance] setAuthTokenWith:[[NSUserDefaults standardUserDefaults] objectForKey:@"uber_token"]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[UberKit sharedInstance] getUserProfileWithCompletionHandler:^(UberProfile *profile, NSURLResponse *response, NSError *error) {
            if (!error) {
                self.profile = profile;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:@"My Profile" message:[NSString stringWithFormat:@"response: %@\nProfile object: %@\nFirst name: %@\nLast name: %@\nEmail: %@\nPicture URL: %@\nPromotion code: %@\nUUID: %@", response, profile, profile.first_name, profile.last_name, profile.email, profile.picture, profile.promo_code, profile.uuid] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                });
            } else NSLog(@"error: %@", error);
        }];
    });
}

-(void)calculateUberEstimatePickupTime:(CLLocationCoordinate2D)bd_coords
{
    _uberWaitingMins = @"计算中..";
    [_carTypeCollectionView reloadData];
    UberKit *uberKit = [[UberKit alloc] initWithServerToken:uServerToken];
    
    CLLocation *pickupLocation = [[CLLocation alloc] initWithLatitude:bd_coords.latitude longitude:bd_coords.longitude];
    
    [uberKit getTimeForProductArrivalWithLocation:pickupLocation withCompletionHandler:^(NSArray *times, NSURLResponse *response, NSError *error) {
        if(!error)
        {
            if ([times count]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSMutableArray *estimatedTimes = @[].mutableCopy;
                    for (UberTime *time in times) {
                        [estimatedTimes addObject:time];
                    }
                    NSSortDescriptor *sortedDescriptor = [[NSSortDescriptor alloc] initWithKey:@"estimate" ascending:YES];
                    NSArray *sortedTimes = [estimatedTimes sortedArrayUsingDescriptors:@[sortedDescriptor]];
                    UberTime *soonest = [sortedTimes firstObject];
                    _estimateTime = soonest;
                    _uberWaitingMins = [NSString stringWithFormat:@"%.1f分后可接驾", soonest.estimate/60];
                    [_carTypeCollectionView reloadData];
                });
            }
        }
        else
        {
            NSLog(@"Error %@", error);
            [[[UIAlertView alloc] initWithTitle:@"错误" message:[NSString stringWithFormat:@"错误信息：\n%@", error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }];
}

-(BOOL)isUberTokenAvailable
{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"uber_token"]) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - Helpers

-(void)loadCollectionView
{
    _carTypeCollectionView = [[HKCarTypeCollectionView alloc] initWithFrame:CGRectMake(0, bHeight - bMenuHeight, bWidth, bMenuHeight/2) collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [_carTypeCollectionView registerClass:[HKCarTypeCollectionViewCell class] forCellWithReuseIdentifier:@"reuseCell"];
    _carTypeCollectionView.dataSource = self;
    _carTypeCollectionView.delegate = self;
    [self.view addSubview:_carTypeCollectionView];
}

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

    [_menuView.destLbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDestinationLabel:)]];
    [_menuView.requestBtn addTarget:self action:@selector(requestButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_menuView.compareBtn addTarget:self action:@selector(compareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
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

-(NSAttributedString *)attributedStringForBrandLabel:(NSString *)string
{
    NSAttributedString *aString = [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13.f]}];
    return aString;
}

-(void)setUberAuthParams
{
    [[UberKit sharedInstance] setClientID:uClientId];
    [[UberKit sharedInstance] setClientSecret:uSecret];
    [[UberKit sharedInstance] setRedirectURL:uRedirectUrl];
    [[UberKit sharedInstance] setApplicationName:uAppName];
    [[UberKit sharedInstance] setServerToken:uServerToken];
    
    UberKit *uberKit = [UberKit sharedInstance];
    uberKit.delegate = self;
    [uberKit startLogin];
}

-(void)startDestReverseGeoCode
{
    BMKReverseGeoCodeOption *reverseDestOption = [[BMKReverseGeoCodeOption alloc] init];
    CLLocation *destLoc = _destLocation[@"dest_pt"];
    reverseDestOption.reverseGeoPoint = destLoc.coordinate;
    BOOL flag = [_searcherForDestination reverseGeoCode:reverseDestOption];
    if (!flag) {
        NSLog(@"destination reverseGeoCode failure, flag = %d", flag);
    }
}

-(void)startReverseGeoCode
{
    CLLocationCoordinate2D centerCoor = [_mapView convertPoint:_centerPinView.center toCoordinateFromView:_mapView];
    BMKReverseGeoCodeOption *reverseGeoCodeOption = [[BMKReverseGeoCodeOption alloc] init];
    reverseGeoCodeOption.reverseGeoPoint = centerCoor;
    [self calculateUberEstimatePickupTime:centerCoor];
    BOOL aflag = [_searcher reverseGeoCode:reverseGeoCodeOption];
    if (!aflag) {
        NSLog(@"reverseGeoCode failure, flag = %d", aflag);
    }
}

#pragma mark - UIButtons & Gesture callbacks

-(void)compareButtonPressed:(UIButton *)sender
{
    [[[UIAlertView alloc] initWithTitle:@"尚未开通" message:@"功能研发中。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

-(void)requestButtonPressed:(UIButton *)sender
{
    if (_startLocation[@"start_array"] && _destLocation[@"dest_array"]) {
        HKDetailViewController *detailVC = [[HKDetailViewController alloc] init];
        detailVC.view.backgroundColor = [UIColor whiteColor];
        detailVC.startLocation = [[NSDictionary alloc] initWithDictionary:_startLocation];
        detailVC.destLocation = [[NSDictionary alloc] initWithDictionary:_destLocation];
        detailVC.estimateTime = _estimateTime;
        [self.navigationController pushViewController:detailVC animated:YES];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"信息不完整" message:@"请确认上车地点和目的地。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

-(void)profileBarButtonPressed
{
    NSLog(@"profileBarButtomPressed");
    if (!_profile.uuid) {
        [self uberRequestProfile];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"My Profile" message:[NSString stringWithFormat:@"First name: %@\nLast name: %@\nEmail: %@\nPicture URL: %@\nPromotion code: %@\nUUID: %@", _profile.first_name, _profile.last_name, _profile.email, _profile.picture, _profile.promo_code, _profile.uuid] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

-(void)settingsBarbuttonPressed
{
    NSLog(@"settingsBarbuttonPressed");
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
        _menuView.destLbl.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"您的目的地:%@", name] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13.f]}];
        NSMutableArray *addressArray = [NSMutableArray array];
        [addressArray addObject:name];
        _destLocation = @{@"dest_array": addressArray, @"dest_pt": [[CLLocation alloc] initWithLatitude:pt.latitude longitude:pt.longitude]}.mutableCopy;
        [self startDestReverseGeoCode];
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
        if ([searcher isEqual:_searcherForDestination]) {
            [_destLocation[@"dest_array"] addObject:pickupInfo.address];
        }
        else
        {
            NSString *pickupAddress = pickupInfo.name;
            _paopaoView.addrLbl.text = [NSString stringWithFormat:@"从%@上车", pickupAddress];
            [_paopaoView.addrLbl sizeToFit];
            
            [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:10.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                _paopaoView.frame = CGRectMake(0, 0, _paopaoView.addrLbl.frame.size.width + 10, _paopaoView.addrLbl.frame.size.height + 10);
                _paopaoView.center = _paopaoCenter;
            } completion:^(BOOL finished) {
            }];
            NSMutableArray *startArray = [NSMutableArray array];
            [startArray addObject:pickupAddress];
            [startArray addObject:pickupInfo.address];
            _startLocation = @{@"start_array": startArray, @"start_pt": [[CLLocation alloc] initWithLatitude:pickupInfo.pt.latitude longitude:pickupInfo.pt.longitude]}.mutableCopy;
        }
    }
    else
    {
        NSLog(@"error: %u", error);
        [[[UIAlertView alloc] initWithTitle:@"错误" message:[NSString stringWithFormat:@"错误信息：\n%u", error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
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
        
        [self startReverseGeoCode];
        if (_destLocation[@"dest_pt"]) {
            [self startDestReverseGeoCode];
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
        _curPinView.image = [UIImage imageNamed:@"hk_cur_12"];
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

#pragma mark - UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 5;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HKCarTypeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"reuseCell" forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case 0: //Uber
            cell.brandTextLabel.attributedText = [self attributedStringForBrandLabel:@"优步"];
            cell.brandIconView.image = [UIImage imageNamed:@"hk_uber_icon"];
            if (_uberWaitingMins) {
                cell.waitingTimeLabel.attributedText = [[NSAttributedString alloc] initWithString:_uberWaitingMins attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:10.f]}];
            } else {
                cell.waitingTimeLabel.text = @"";
            }
            break;
        case 1: //滴滴打车
            cell.brandTextLabel.attributedText = [self attributedStringForBrandLabel:@"滴滴打车"];
            cell.brandIconView.image = [UIImage imageNamed:@"hk_didi_icon"];
            cell.waitingTimeLabel.text = @"";
            break;
        case 2:
            cell.brandTextLabel.attributedText = [self attributedStringForBrandLabel:@"快的打车"];
            cell.brandIconView.image = [UIImage imageNamed:@"hk_kuaidi_icon"];
            cell.waitingTimeLabel.text = @"";
            break;
        case 3:
            cell.brandTextLabel.attributedText = [self attributedStringForBrandLabel:@"神州专车"];
            cell.brandIconView.image = [UIImage imageNamed:@"hk_shenzhou_icon"];
            cell.waitingTimeLabel.text = @"";
            break;
        case 4:
            cell.brandTextLabel.attributedText = [self attributedStringForBrandLabel:@"51用车"];
            cell.brandIconView.image = [UIImage imageNamed:@"hk_51_icon"];
            cell.waitingTimeLabel.text = @"";
            break;
            
        default:
            break;
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_isCenter) {
        cell.contentView.transform = CGAffineTransformMakeScale(0.5, 0.5);
        [UIView beginAnimations:nil context:UIGraphicsGetCurrentContext()];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:2.0];
        cell.contentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        [UIView commitAnimations];
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"selected %ld", indexPath.row);
    NSLog(@"select start: %@ %@, end: %@ %@", [_startLocation[@"start_array"] firstObject], [_startLocation[@"start_array"] objectAtIndex:1], [_destLocation[@"dest_array"] firstObject], [_destLocation[@"dest_array"] objectAtIndex:1]);

    if (0 == indexPath.row) { //UBER
        if (![self isUberTokenAvailable]) {
            _alertView = [[UIAlertView alloc] initWithTitle:@"登陆" message:@"您尚未授权优步账号，请先登陆授权后使用。" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登陆优步", nil];
            [_alertView show];
        } else {
            //可跳转Uber 设置优步绿色标志位
            [[[UIAlertView alloc] initWithTitle:@"已授权" message:@"您已授权打车神器使用您的优步账号，请点击叫车按键进行叫车（暂时仅支持人民优步车型）。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }
}

#pragma mark - UberKitDelegate

-(void)uberKit:(UberKit *)uberKit didReceiveAccessToken:(NSString *)accessToken
{
    NSLog(@"Received access token: %@", accessToken);
    _accessToken = accessToken;
    [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:@"uber_token"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)uberKit:(UberKit *)uberKit loginFailedWithError:(NSError *)error
{
    NSLog(@"Failed with error: %@", error);
    [[[UIAlertView alloc] initWithTitle:@"错误" message:[NSString stringWithFormat:@"错误信息：\n%@", error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView isEqual:_alertView]) {
        if (1 == buttonIndex) {
            //login uber
            [self setUberAuthParams];
        }
    }
}

@end
