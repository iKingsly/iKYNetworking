//
//  ViewController.m
//  iKYNetworking
//
//  Created by 郑钦洪 on 16/1/23.
//  Copyright © 2016年 iKingsly. All rights reserved.
//

#import "ViewController.h"
#import "iKYNetworking.h"
#import "AFNetworking.h"

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

    // 由于这里有两套基础路径，用时就需要更新
//    [iKYNetworking setUpBaseUrl:@"http://www.baidu.com"];
//   [iKYNetworking postWithUrlString:path params:nil success:^(id response) {
//
//   } fail:^(NSError *error) {
//
//   }];

    NSString *urlPath = @"http://piao.zhongchengbus.cn/api/QueryRecommendLines";
;
    NSString *baiduURL = @"http://www.baidu.com";
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"CityName"] = @"";


//    [iKYNetworking postWithUrlString:urlPath params:dict success:^(id response) {
//        NSLog(@"%@",response);
//    } fail:^(NSError *error) {
//        NSLog(@"%@",error);
//    }];

    [iKYNetworking getWithUrlString:urlPath success:^(id response) {
        NSLog(@"%@",response);
    } fail:^(NSError *error) {
        NSLog(@"%@",error);
    }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
