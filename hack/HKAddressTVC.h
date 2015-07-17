//
//  HKAddressTVC.h
//  hack
//
//  Created by Zhouboli on 15/7/15.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BaiduMapAPI/BMapKit.h>

@interface HKAddressTVC : UIViewController

@property (nonatomic) BMKMapRect *pickupRect;
@property (strong, nonatomic) BMKReverseGeoCodeResult *pickupResult;

@end
