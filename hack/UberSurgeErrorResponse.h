//
//  UberSurgeErrorResponse.h
//  hack
//
//  Created by Zhouboli on 15/7/22.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UberSurgeConfirmation.h"

@interface UberSurgeErrorResponse : NSObject

@property (strong, nonatomic) UberSurgeConfirmation *surge_confirmation;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
