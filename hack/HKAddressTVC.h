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
-(void)userSelectedPoiPt:(CLLocationCoordinate2D)pt poiName:(NSString *)name forDestination:(BOOL)isDestination;

@end

@interface HKAddressTVC : UIViewController

@property (weak, nonatomic) id <HKAddressTVDelegate> delegate;

@property (strong, nonatomic) BMKReverseGeoCodeResult *pickupResult;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (nonatomic) BOOL isDestination;

@end
