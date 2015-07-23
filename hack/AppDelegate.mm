//
//  AppDelegate.m
//  hack
//
//  Created by Zhouboli on 15/7/15.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import <BaiduMapAPI/BMapKit.h>

#import "AppDelegate.h"
#import "HKMainMapViewController.h"
#import "UberKit.h"

#import "UIViewController+Extension.h"

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height

@interface AppDelegate ()

@property (strong, nonatomic) BMKMapManager *mapManager;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, bWidth, bHeight)];
    
    _mapManager = [[BMKMapManager alloc] init];
    BOOL ret = [_mapManager start:@"hKll69qmyFfq1UhUkQj0kH6K" generalDelegate:nil];
    
    if (!ret) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Baidu map manager failed to start." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
    HKMainMapViewController *mmvc = [[HKMainMapViewController alloc] init];
    mmvc.title = @"Hack";
    //mmvc.view.backgroundColor = [UIColor whiteColor];
    UINavigationController *mapNvc = [[UINavigationController alloc] initWithRootViewController:mmvc];
    
    self.window.rootViewController = mapNvc;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"url is: %@", url);
    return [[UberKit sharedInstance] handleLoginRedirectFromUrl:url sourceApplication:sourceApplication];
}

@end
