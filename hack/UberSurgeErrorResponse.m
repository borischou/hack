//
//  UberSurgeErrorResponse.m
//  hack
//
//  Created by Zhouboli on 15/7/22.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "UberSurgeErrorResponse.h"

@implementation UberSurgeErrorResponse

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        if (![dictionary[@"meta"] isEqual:[NSNull null]]) {
            if (![dictionary[@"meta"][@"surge_confirmation"] isEqual:[NSNull null]]) {
                _surge_confirmation = dictionary[@"meta"][@"surge_confirmation"];
            }
        }
    }
    return self;
}

@end
