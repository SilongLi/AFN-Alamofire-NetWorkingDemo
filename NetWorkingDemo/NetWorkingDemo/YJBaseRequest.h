//
//  YJBaseRequest.h
//  NetWorking
//
//  Created by lisilong on 2017/9/18.
//  Copyright © 2017年 LongDream. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - 网络请求基类

@interface YJBaseRequest : NSObject

@property (nonatomic, copy) NSString *urlString;                  // 接口路径 
@property (nonatomic, strong, readonly) NSDictionary *parameters; // 返回请求参数

@property (nonatomic, copy) NSString *nameTest;
@property (nonatomic, copy) NSString *valueTest;


- (instancetype)initWithUrlString:(NSString *)urlString;

@end

#pragma mark - 分页加载数据网络请求基类

@interface YJBaseTableRequest : YJBaseRequest

@property (nonatomic, assign) NSInteger nowPage;    // 当前页，默认1。
@property (nonatomic, assign) NSInteger pageSize;   // 分页值，默认10。

@end
