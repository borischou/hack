//
//  HKMapPaopaoViewController.h
//  hack
//
//  Created by Zhouboli on 15/7/15.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HKMapPaopaoViewDelegate <NSObject>

@optional
-(void)pushToAddressView;

@end

@interface HKMapPaopaoViewController : UIViewController

@property (weak, nonatomic) id <HKMapPaopaoViewDelegate> delegate;

@property (copy, nonatomic) NSString *address;
@property (strong, nonatomic) UILabel *addrLbl;

@end
