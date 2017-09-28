//
//  YJBaseRequest.m
//  NetWorking
//
//  Created by lisilong on 2017/9/18.
//  Copyright © 2017年 LongDream. All rights reserved.
//

#import "YJBaseRequest.h"

@implementation YJBaseRequest

- (instancetype)initWithUrlString:(NSString *)urlString {
    if (self = [super init]) {
        _urlString = [urlString copy];
    }
    return self;
}

- (NSDictionary *)parameters {
    return [self mj_keyValuesWithIgnoredKeys:@[@"urlString", @"showHUD", @"parameters"]];
}


@end

@implementation YJBaseTableRequest

- (instancetype)init {
    if (self = [super init]) {
        _pageSize = 10;
        _nowPage  = 1;
    }
    return self;
}

- (instancetype)initWithUrlString:(NSString *)urlString {
    if (self = [super initWithUrlString:urlString]) {
        _pageSize = 10;
        _nowPage  = 1;
    }
    return self;
}

@end
