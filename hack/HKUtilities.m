//
//  HKUtilities.m
//  hack
//
//  Created by Zhouboli on 15/7/21.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "HKUtilities.h"

@implementation HKUtilities

// 圆周率
static double pi = 3.14159265358979324;
// 长轴半径
static double a = 6378245.0;
// WGS 偏心率的平方
static double ee = 0.00669342162296594323;
// 计算百度坐标参数
static double x_pi = 3.14159265358979324 * 3000.0 / 180.0;

//百度->火星
-(CLLocationCoordinate2D)transformToMarsCoordsFromBaiduCoords:(CLLocationCoordinate2D)bd_coords
{
    double x = bd_coords.latitude - 0.0065, y = bd_coords.longitude - 0.006;
    double z = sqrt(x * x + y * y) - 0.00002 * sin(y * x_pi);
    double theta = atan2(y, x) - 0.000003 * cos(x * x_pi);
    return CLLocationCoordinate2DMake(z * cos(theta), z * sin(theta));
}

//地球->火星
-(CLLocationCoordinate2D)transformToMarsCoordsFromGPSCoords:(CLLocationCoordinate2D)gps_coords
{
    if ([self outOfChina:gps_coords]) {
        return CLLocationCoordinate2DMake(gps_coords.latitude, gps_coords.longitude);
    }
    double dLat = [self transformLatitudeX:gps_coords.longitude-105.0 Y:gps_coords.latitude-35.0];
    double dLon = [self transformLongitudeX:gps_coords.longitude-105.0 Y:gps_coords.latitude-35.0];
    
    double radLat = gps_coords.latitude/180.0 * x_pi;
    double magic = sin(radLat);
    
    magic = 1 - ee * magic * magic;
    double sqrtMagic  = sqrt(magic);
    
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi);
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi);
    
    return CLLocationCoordinate2DMake(gps_coords.latitude+dLat, gps_coords.longitude+dLon);
}

//火星->地球
-(CLLocationCoordinate2D)transformToGPSCoordsFromMarsCoords:(CLLocationCoordinate2D)mars_coords
{
    double gLat, gLon;
    CLLocationCoordinate2D gpsCoords = CLLocationCoordinate2DMake(mars_coords.latitude, mars_coords.longitude);
    gLat = mars_coords.latitude - (gpsCoords.latitude - mars_coords.latitude);
    gLon = mars_coords.longitude - (gpsCoords.longitude - mars_coords.longitude);
    
    return CLLocationCoordinate2DMake(gLat, gLon);
}

-(double)transformLatitudeX:(double)x Y:(double)y
{
    double ret;
    
    ret = 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y - 100.0;
    ret = ret + 0.2 * sqrt(fabs(x));
    
    ret = ret + (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret = ret + (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0;
    ret = ret + (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0;
    
    return ret;
}

-(double)transformLongitudeX:(double)x Y:(double)y
{
    double ret;
    
    ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y;
    ret = ret + 0.1 * sqrt(fabs(x));
    
    ret = ret + 20.0 * sin(6.0 * x * pi);
    ret = ret + 20.0 * sin(2.0 * x * pi) * 2.0 / 3.0;
    ret = ret + (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0;
    ret = ret + (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0;
    
    return ret;
}

-(BOOL)outOfChina:(CLLocationCoordinate2D)coords
{
    if (coords.longitude < 72.004 || coords.longitude > 137.8347) {
        return YES;
    }
    if (coords.latitude < 0.8293 || coords.latitude > 55.8271) {
        return YES;
    }
    return NO;
}

@end
