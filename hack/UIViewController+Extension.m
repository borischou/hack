//
//  UIViewController+Extension.m
//  hack
//
//  Created by Zhouboli on 15/7/23.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "UIViewController+Extension.h"
#import <objc/runtime.h>

@implementation UIViewController (Extension)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originalMethod = class_getInstanceMethod([self class], @selector(viewDidLoad));
        Method swizzledMethod = class_getInstanceMethod([self class], @selector(swizzled_viewDidLoad));
        BOOL didAddMethod = class_addMethod([self class], @selector(viewDidLoad), method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            class_replaceMethod([self class], @selector(swizzled_viewDidLoad), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)swizzled_viewDidLoad {
    [self swizzled_viewDidLoad];
    NSLog(@"%@ loaded swizzled_viewDidLoad", self);
    
    if (![self isKindOfClass:NSClassFromString(@"UIInputWindowController")]) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
}

@end