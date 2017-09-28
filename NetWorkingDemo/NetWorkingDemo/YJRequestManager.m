//
//  YJRequestManager.m
//  NetWorking
//
//  Created by lisilong on 17/8/10.
//  Copyright © 2017年 LongDream. All rights reserved.
//

#import "YJRequestManager.h"
#import <AFNetworking/AFNetworking.h>


#ifdef DEBUG
NSString * const YJBaseURLString = @"http://app.join51.com/";    // 开发环境

#else
NSString * const YJBaseURLString = @"http://app.join51.com/";    // 生产环境
#endif


typedef NS_ENUM(NSInteger, YJRequestType) {
    YJRequestTypeGet,
    YJRequestTypePost,
};

typedef NS_ENUM(NSInteger, YJResponseCode) {
    YJResponseCodeSuccess            = 0,        // 请求成功
    YJResponseCodeRemoteLogined      = 7777,     // 异地登录
    YJResponseCodeTokenInvalid       = 9998,     // token失效
};

@interface YJRequestManager ()
@property (nonatomic, strong) AFHTTPSessionManager *httpSessionManager;
@end

@implementation YJRequestManager

+ (instancetype)shareManager {
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[[self class] alloc] init];
    });
    return manager;
}

#pragma mark - request

- (void)get:(YJBaseRequest *)request completion:(CompletionHandler)completion {
    [self logRequestInfoWithType:YJRequestTypeGet request:request];
    [self requestWithType:YJRequestTypeGet request:request completion:completion];
}

- (void)post:(YJBaseRequest *)request completion:(CompletionHandler)completion {
    [self logRequestInfoWithType:YJRequestTypePost request:request];
    [self requestWithType:YJRequestTypePost request:request completion:completion];
}

- (void)getWithUrlString:(NSString *)urlString completion:(CompletionHandler)completion {
    YJBaseRequest *request = [[YJBaseRequest alloc] initWithUrlString:urlString];
    [self logRequestInfoWithType:YJRequestTypeGet request:request];
    [self requestWithType:YJRequestTypeGet request:request completion:completion];
}

- (void)postWithUrlString:(NSString *)urlString completion:(CompletionHandler)completion {
    YJBaseRequest *request = [[YJBaseRequest alloc] initWithUrlString:urlString];
    [self logRequestInfoWithType:YJRequestTypePost request:request];
    [self requestWithType:YJRequestTypePost request:request completion:completion];
}

- (void)requestWithType:(YJRequestType)type request:(YJBaseRequest *)request completion:(CompletionHandler)completion {
    if (request.urlString.length == 0) {
#ifdef DEBUG
        [SVProgressHUD showInfoWithStatus:@"兄弟，你没有设置请求路径。"];
#endif
        completion ? completion(NO, nil) : nil;
        return;
    }
    [self setupHttpSessionManagerHeader];
    
    YJWeakSelf;
    switch (type) {
        case YJRequestTypeGet: {
            [self.httpSessionManager GET:request.urlString parameters:request.parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf handleResponseResultsWithResponse:responseObject httpResponse:(NSHTTPURLResponse *)task.response error:nil completion:completion];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf handleResponseResultsWithResponse:nil httpResponse:(NSHTTPURLResponse *)task.response error:error completion:completion];
            }];
        }
            break;
        case YJRequestTypePost: {
            [self.httpSessionManager POST:request.urlString parameters:request.parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf handleResponseResultsWithResponse:responseObject httpResponse:(NSHTTPURLResponse *)task.response error:nil completion:completion];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf handleResponseResultsWithResponse:nil httpResponse:(NSHTTPURLResponse *)task.response error:error completion:completion];
            }];
        }
            break;
        default: {
            [SVProgressHUD showInfoWithStatus:@"未知请求。"];
            completion ? completion(NO, nil) : nil;
        }
            break;
    }
}

- (void)setupHttpSessionManagerHeader {
    // 设置请求头信息，比如token等
}

#pragma mark - 统一处理网络请求返回值

- (void)handleResponseResultsWithResponse:(id)responseObject
                             httpResponse:(NSHTTPURLResponse *)httpResponse
                                    error:(NSError *)error
                               completion:(CompletionHandler)completion {
    // 网络请求失败，上报Bugly
    NSInteger statusCode = httpResponse.statusCode;
    if (httpResponse && statusCode != 200) {
        // TODO: 上报异常
#ifdef DEBUG
        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"statusCode = %ld, error = %@",statusCode, error.localizedDescription]];
#else
        [SVProgressHUD showInfoWithStatus:@"网络繁忙，请稍后重试！"];
#endif
        completion ? completion(NO, nil) : nil;
        return;
    }
    
    NSString *info = responseObject[@"resultMsg"];
    if (responseObject[@"resultCode"] == nil) {
        completion ? completion(NO, nil) : nil;
        [self showMessageWithError:error info:info];
        return;
    }
    
    NSInteger code = [responseObject[@"resultCode"] integerValue];
    switch (code) {
        case YJResponseCodeSuccess: {                                // 请求成功
            completion ? completion(YES, responseObject) : nil;
        }
            break;
        case YJResponseCodeTokenInvalid: {                           // token失效
            completion ? completion(NO, nil) : nil;
            // TODO: token失效处理
        }
            break;
        case YJResponseCodeRemoteLogined: {                          // 异地登录
            completion ? completion(NO, nil) : nil;
            // TODO: 异地登录处理
        }
            break;
        default: {                                                   // 其它错误
            completion ? completion(NO, nil) : nil;
            [self showMessageWithError:error info:info];
        }
            break;
    }
}

- (void)showMessageWithError:(NSError *)error info:(NSString *)info {
    if (error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    } else {
        if (info.length > 0) {
            [SVProgressHUD showErrorWithStatus:info];
        } else {
            [SVProgressHUD showInfoWithStatus:@"网络繁忙，请稍后重试！"];
        }
    }
}

#pragma mark - 打印网络请求信息

- (void)logRequestInfoWithType:(YJRequestType)type  request:(YJBaseRequest *)request {
    NSString *methodStr = (type == YJRequestTypeGet ? @"GET" : @"POST");
    NSLog(@"\n\n  type:%@\n  Url: %@%@\n  params: %@\n%@\n\n", methodStr, YJBaseURLString, request.urlString, request.parameters, self.httpSessionManager.requestSerializer.HTTPRequestHeaders);
}

#pragma mark - setter and getter

- (AFHTTPSessionManager *)httpSessionManager {
    if (!_httpSessionManager) {
        _httpSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:YJBaseURLString]];
        //----- http header
        [_httpSessionManager.requestSerializer setValue:@"4" forHTTPHeaderField:@"platform"];
        [_httpSessionManager.requestSerializer setValue:[UIDevice currentDevice].systemVersion forHTTPHeaderField:@"sdkVersion"];
        [_httpSessionManager.requestSerializer setValue:YJAppVersion forHTTPHeaderField:@"version"];
        //----- https 适配 SecurityPolicy
//        _httpSessionManager.securityPolicy = [YJRequestManager customSecurityPolicy];
        _httpSessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", nil];
    }
    return _httpSessionManager;
}

+ (AFSecurityPolicy*)customSecurityPolicy {
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"ymsj" ofType:@"cer"];//证书的路径
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    
    // AFSSLPinningModeCertificate 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    
    // allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    // 如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    
    //validatesDomainName 是否需要验证域名，默认为YES；
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    securityPolicy.validatesDomainName = NO;
    securityPolicy.pinnedCertificates = [NSSet setWithObjects:certData, nil];
    return securityPolicy;
}

@end
