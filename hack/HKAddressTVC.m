//
//  HKAddressTVC.m
//  hack
//
//  Created by Zhouboli on 15/7/15.
//  Copyright (c) 2015年 Bankwel. All rights reserved.
//

#import "HKAddressTVC.h"
#import <BaiduMapAPI/BMapKit.h>

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height
#define bTableViewHeight bHeight/2
#define bMapViewHeight bHeight - bTableViewHeight

@interface HKAddressTVC () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, BMKMapViewDelegate, BMKSuggestionSearchDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) BMKSuggestionSearch *searcher;
@property (strong, nonatomic) BMKSuggestionResult *suggestionResult;

@end

@implementation HKAddressTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _searchBar = [[UISearchBar alloc] init];
    _searchBar.delegate = self;
    self.navigationItem.titleView = _searchBar;
    
    _searcher = [[BMKSuggestionSearch alloc] init];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, bWidth, bHeight) style:UITableViewStylePlain];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _searcher.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _searcher.delegate = nil;
}

#pragma mark - UISearchBarDelegate

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"searchBarTextDidBeginEditing");
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    NSLog(@"searchBarTextDidEndEditing");
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    BMKSuggestionSearchOption* option = [[BMKSuggestionSearchOption alloc] init];
    option.cityname = @"北京";
    option.keyword  = searchText;
    BOOL flag = [_searcher suggestionSearch:option];
    if(!flag)
    {
        NSLog(@"建议检索发送失败");
    }
}

#pragma mark - BMKSuggestionSearchDelegate

-(void)onGetSuggestionResult:(BMKSuggestionSearch *)searcher result:(BMKSuggestionResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (error == BMK_SEARCH_NO_ERROR) {
        //在此处理正常结果
        _suggestionResult = result;
        [self.tableView reloadData];
    }
    else {
        NSLog(@"抱歉，未找到结果");
    }
}

#pragma mark - Table view data source & delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_suggestionResult) {
        return [_suggestionResult.keyList count];
    } else
    {
        return [_pickupResult.poiList count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"reuse"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuse" forIndexPath:indexPath];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (_suggestionResult) {
        cell.textLabel.text = [_suggestionResult.keyList objectAtIndex:indexPath.row];
    }
    else
    {
        BMKPoiInfo *poiInfo = [_pickupResult.poiList objectAtIndex:indexPath.row];
        if (0 == indexPath.row) {
            cell.textLabel.text = [NSString stringWithFormat:@"当前: %@", poiInfo.name];
            cell.textLabel.textColor = [UIColor blueColor];
        } else {
            cell.textLabel.text = poiInfo.name;
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_suggestionResult) {
        CLLocationCoordinate2D pt;
        [[_suggestionResult.ptList objectAtIndex:indexPath.row] getValue:&pt];
        [self.delegate userSelectedPoiPt:pt poiName:[_suggestionResult.keyList objectAtIndex:indexPath.row] forDestination:_isDestination];
    }
    else
    {
        BMKPoiInfo *info = [_pickupResult.poiList objectAtIndex:indexPath.row];
        [self.delegate userSelectedPoiPt:info.pt poiName:info.name forDestination:_isDestination];
    }
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
