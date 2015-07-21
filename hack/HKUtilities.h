//
//  HKUtilities.h
//  hack
//
//  Created by Zhouboli on 15/7/21.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface HKUtilities : NSObject

//百度->火星
+(CLLocationCoordinate2D)transformToMarsCoordsFromBaiduCoords:(CLLocationCoordinate2D)bd_coords;

//地球->火星
+(CLLocationCoordinate2D)transformToMarsCoordsFromGPSCoords:(CLLocationCoordinate2D)gps_coords;

//火星->地球
+(CLLocationCoordinate2D)transformToGPSCoordsFromMarsCoords:(CLLocationCoordinate2D)mars_coords;

@end
