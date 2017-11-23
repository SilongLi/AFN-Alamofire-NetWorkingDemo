//
//  YJRequestManager.h
//  NetWorking
//
//  Created by lisilong on 17/8/10.
//  Copyright © 2017年 LongDream. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YJBaseRequest;

#ifdef DEBUG
extern NSString * const YJBaseURLString;
extern NSString * const YJBaseWebURLString;
#else
extern NSString * const YJBaseURLString;
extern NSString * const YJBaseWebURLString;
#endif

extern NSString * const YJCerFileName;

typedef void(^CompletionHandler)(BOOL success, id responseObject);


@interface YJRequestManager : NSObject

+ (instancetype)shareManager;

/**
 Get方式的网络请求
 * request : 网络请求配置（路径、参数等等）
 * CompletionHandler : 网络回调
 *      success : ture表示此次网络请求成功, 否则失败（false）
 *      responseObject : 返回id类型的数据
 */
- (void)get:(YJBaseRequest *)request completion:(CompletionHandler)completion;

/**
 Post方式的网络请求
 * request : 网络请求配置（路径、参数等等）
 * RequestCompletion : 网络回调
 *      success : ture表示此次网络请求成功, 否则失败（false）
 *      responseObject : 返回id类型的数据
 */
- (void)post:(YJBaseRequest *)request completion:(CompletionHandler)completion;


- (void)getWithUrlString:(NSString *)urlString completion:(CompletionHandler)completion;

- (void)postWithUrlString:(NSString *)urlString completion:(CompletionHandler)completion;


/**
 统一处理网络返回值
 */
- (void)handleResponseResultsWithResponse:(id)responseObject httpResponse:(NSHTTPURLResponse *)httpResponse error:(NSError *)error completion:(CompletionHandler)completion;

@end
