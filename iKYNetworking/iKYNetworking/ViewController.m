//
//  ViewController.m
//  iKYNetworking
//
//  Created by 郑钦洪 on 16/1/23.
//  Copyright © 2016年 iKingsly. All rights reserved.
//

#import "ViewController.h"
#import "iKYNetworking.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // 测试POST API：
    // 假数据
    NSDictionary *postDict = @{ @"urls": @[@"http://www.henishuo.com/git-use-inwork/",
                                           @"http://www.henishuo.com/ios-open-source-hybloopscrollview/"]
                                };
    NSString *path = @"/urls?site=www.henishuo.com&token=bRidefmXoNxIi3Jp";
    // 由于这里有两套基础路径，用时就需要更新
    [iKYNetworking setUpBaseUrl:@"http://data.zz.baidu.com"];
    [iKYNetworking postWithUrlString:path params:postDict cacheDataPolicy:iKYCahceRequestCachePolicyCacheDataDontLoad success:^(id response) {
    } fail:^(NSError *error) {
        
    }];
    NSString *postURL = @"http://www.henishuo.com/git-use-inwork/?adlfjlasdjf";
    NSRange range = [postURL rangeOfString:@"?"];
    NSLog(@"%@",[postURL substringToIndex:range.location]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
