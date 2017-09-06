//
//  ViewController.m
//  NetWorkingDemo
//
//  Created by lisilong on 17/9/6.
//  Copyright © 2017年 LongShaoDream. All rights reserved.
//

#import "ViewController.h"
#import "NetWorkingDemo-Swift.h"
#import "YJMessageRequest.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self requestDataByOC];
    [self requestDataBySwift];
}

- (void)requestDataByOC {
    NSLog(@"------------OC request---------------");
    YJMessageRequest *request = [[YJMessageRequest alloc] initWithUrlString:@"v1.0/app/news/page"];
    request.newsType = @"1";
    [[YJRequestManager shareManager] post:request completion:^(BOOL success, id responseObject) {
        if (success) {
            NSLog(@"OC 请求数据成功。");
        } else {
            NSLog(@"OC 请求数据失败。");
        }
    }];
}

- (void)requestDataBySwift {
    NSLog(@"------------Swift request---------------");
    [RequestDemo requestData];
}


@end
