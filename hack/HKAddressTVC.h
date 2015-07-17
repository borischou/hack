//
//  HKAddressTVC.h
//  hack
//
//  Created by Zhouboli on 15/7/15.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BaiduMapAPI/BMapKit.h>

@protocol HKAddressTVDelegate <NSObject>

@required
-(void)userSelectedPoiInfo:(BMKPoiInfo *)info;

@end

@interface HKAddressTVC : UIViewController

@property (weak, nonatomic) id <HKAddressTVDelegate> delegate;

@property (strong, nonatomic) BMKReverseGeoCodeResult *pickupResult;

@end
