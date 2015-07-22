//
//  HKDetailViewController.m
//  hack
//
//  Created by Zhouboli on 15/7/21.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "HKDetailViewController.h"
#import "UIButton+Bobtn.h"

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height

@interface HKDetailViewController ()

@property (strong, nonatomic) UILabel *startAddressLabel;
@property (strong, nonatomic) UILabel *destAddressLabel;
@property (strong, nonatomic) UILabel *estimateLabel;

@property (strong, nonatomic) UIButton *confirmButton;
@property (strong, nonatomic) UIButton *estimateButton;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIButton *statusButton;

@property (strong, nonatomic) UberRequest *request;

@property (nonatomic) BOOL isProcessing;

@end

@implementation HKDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"确认页";
    _isProcessing = NO;
    
    _startAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, bHeight*1/8, bWidth-100, bHeight/8)];
    _startAddressLabel.textColor = [UIColor blackColor];
    _startAddressLabel.numberOfLines = 0;
    [self.view addSubview:_startAddressLabel];
    
    _destAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, bHeight*2/8, bWidth-100, bHeight/8)];
    _destAddressLabel.textColor = [UIColor blackColor];
    _destAddressLabel.numberOfLines = 0;
    [self.view addSubview:_destAddressLabel];
    
    _estimateLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, bHeight*3/8, bWidth-100, bHeight/8)];
    _estimateLabel.textColor = [UIColor blackColor];
    _estimateLabel.numberOfLines = 0;
    [self.view addSubview:_estimateLabel];
    
    _confirmButton = [[UIButton alloc] initWithFrame:CGRectMake(50, bHeight*10/20, bWidth-100, bHeight/20) andTitle:@"确认打车" withBackgroundColor:[UIColor blueColor] andTintColor:[UIColor whiteColor]];
    [_confirmButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_confirmButton];
    
    _cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(50, bHeight*12/20, bWidth-100, bHeight/20) andTitle:@"取消打车" withBackgroundColor:[UIColor redColor] andTintColor:[UIColor whiteColor]];
    [_cancelButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_cancelButton];
    
    _statusButton = [[UIButton alloc] initWithFrame:CGRectMake(50, bHeight*14/20, bWidth-100, bHeight/20) andTitle:@"打车状态" withBackgroundColor:[UIColor redColor] andTintColor:[UIColor whiteColor]];
    [_statusButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_statusButton];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"uber token: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"uber_token"]);

    CLLocation *startLoc = [_startLocation objectForKey:@"start_pt"];
    CLLocation *destLoc = [_destLocation objectForKey:@"dest_pt"];
    _startAddressLabel.text = [NSString stringWithFormat:@"上车：%@附近 %@\n%f %f", [_startLocation[@"start_array"] firstObject], [_startLocation[@"start_array"] objectAtIndex:1], startLoc.coordinate.latitude, startLoc.coordinate.longitude];
    _destAddressLabel.text = [NSString stringWithFormat:@"目的地：%@附近 %@\n%f %f", [_destLocation[@"dest_array"] firstObject],[_destLocation[@"dest_array"] objectAtIndex:1], destLoc.coordinate.latitude, destLoc.coordinate.longitude];
    _estimateLabel.text = @"正在请求本次打车预估信息..";
    [self estimateRequest];
}

#pragma mark - UBER

-(void)estimateRequest
{
    [[UberKit sharedInstance] setAuthTokenWith:[[NSUserDefaults standardUserDefaults] objectForKey:@"uber_token"]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[UberKit sharedInstance] getRequestEstimateWithProductId:_estimateTime.productID andStartLocation:[_startLocation objectForKey:@"start_pt"] endLocation:[_destLocation objectForKey:@"dest_pt"] withCompletionHandler:^(UberEstimate *estimateResult, NSURLResponse *response, NSError *error) {
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _estimateLabel.text = [NSString stringWithFormat:@"预估信息：%ld分钟后可接驾；费用：%@%@，倍率：%.1f；行程耗时：%.1f分钟，里程：%.1f%@", estimateResult.pickup_estimate, estimateResult.price.display, estimateResult.price.currency_code, estimateResult.price.surge_multiplier, @(estimateResult.trip.duration_estimate).floatValue/60, estimateResult.trip.distance_estimate, estimateResult.trip.distance_unit];
                });
            }
            else
            {
                [[[UIAlertView alloc] initWithTitle:@"出错了" message:[NSString stringWithFormat:@"错误信息: %@", error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
            
        }];
    });
}

-(void)rideRequest
{
    if (!_isProcessing) {
        CLLocation *startLoc = [_startLocation objectForKey:@"start_pt"];
        CLLocation *destLoc = [_destLocation objectForKey:@"dest_pt"];
        
        NSDictionary *parameters = @{@"product_id": _estimateTime.productID, @"start_latitude": @(startLoc.coordinate.latitude), @"start_longitude": @(startLoc.coordinate.longitude), @"end_latitude": @(destLoc.coordinate.latitude), @"end_longitude": @(destLoc.coordinate.longitude), @"surge_confirmation_id": [NSNull null]};
        
        [[UberKit sharedInstance] getResponseFromRequestWithParameters:parameters withCompletionHandler:^(UberRequest *requestResult, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _request = requestResult;
                NSLog(@"got result");
                [[[UIAlertView alloc] initWithTitle:@"Uber Response" message:[NSString stringWithFormat:@"UberResponse:\nrequest_id: %@\nstatus: %@\neta: %ld\nsurge_multiplier: %f\nvehicle:\nmake: %@\nmodel: %@\nlicense_plate: %@\ndriver:\nphone_number: %@\nname: %@\nrating: %f\nlocation:\nlat: %f lon: %f bearing: %ld\nresponse: %@\nerror: %@", requestResult.request_id, requestResult.status, requestResult.eta, requestResult.surge_multiplier, requestResult.vehicle.make, requestResult.vehicle.model, requestResult.vehicle.license_plate, requestResult.driver.phone_number, requestResult.driver.name, requestResult.driver.rating, requestResult.location.latitude, requestResult.location.longitude, requestResult.location.bearing, response, error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            });
        }];
    } else {
        _confirmButton.enabled = NO;
    }
}

-(void)cancelRequest
{
    if (_request.request_id) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[UberKit sharedInstance] cancelRequestForId:_request.request_id withCompletionHandler:^(NSURLResponse *response, NSError *error) {
                if (!error) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:@"Cancel" message:[NSString stringWithFormat:@"Response: %ld\n(204为取消成功)", httpResponse.statusCode] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                        _isProcessing = NO;
                        _confirmButton.enabled = YES;
                    });
                }
                else
                {
                    [[[UIAlertView alloc] initWithTitle:@"出错了" message:[NSString stringWithFormat:@"错误信息: %@", error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
                
            }];
        });
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"出错了" message:@"您尚未发起任何打车请求。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

-(void)statusRequest
{
    if (_request.request_id) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[UberKit sharedInstance] getDetailsFromRequestId:_request.request_id withCompletionHandler:^(UberRequest *requestResult, NSURLResponse *response, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:@"Uber Response" message:[NSString stringWithFormat:@"UberResponse:\nrequest_id: %@\nstatus: %@\neta: %ld\nsurge_multiplier: %f\nvehicle:\nmake: %@\nmodel: %@\nlicense_plate: %@\ndriver:\nphone_number: %@\nname: %@\nrating: %f\nlocation:\nlat: %f lon: %f bearing: %ld\nresponse: %@\nerror: %@", requestResult.request_id, requestResult.status, requestResult.eta, requestResult.surge_multiplier, requestResult.vehicle.make, requestResult.vehicle.model, requestResult.vehicle.license_plate, requestResult.driver.phone_number, requestResult.driver.name, requestResult.driver.rating, requestResult.location.latitude, requestResult.location.longitude, requestResult.location.bearing, response, error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                });
            }];
        });
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"出错了" message:@"您尚未发起任何打车请求。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

#pragma mark - UIButtons

-(void)buttonPressed:(UIButton *)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        if ([button.titleLabel.text isEqualToString:@"确认打车"]) {
            [self rideRequest];
        }
        if ([button.titleLabel.text isEqualToString:@"取消打车"]) {
            [self cancelRequest];
        }
        if ([button.titleLabel.text isEqualToString:@"打车状态"]) {
            [self statusRequest];
        }
    }
}
























@end