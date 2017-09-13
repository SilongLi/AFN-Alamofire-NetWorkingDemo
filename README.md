# NetWorkingDemo

## 简介
- 使用YJBaseRequest和YJBaseTableRequest两个基类统一管理网络请求需要的参数；
- 使用两套请求方案，在请求上OC使用AFN，Swift使用Alamofire；在返回结果上首先会调用一个统一过滤返回结果的方法，最后才会把结果抛出来，这样其他人在调用的时候，只需要简单的判断这次请求是否有效的，做相应的处理就行了。
- 在返回数据方面：OC我会返回id类型的响应值，相当于不做处理，在请求端选择相应的JSON转模型的框架。但是在Swift方面，我会直接使用一个我非常非常喜欢的框架SwiftyJSON，给调用者直接返回一个json格式的对象，这样在调用者根本不用怕，因没有获取到相应的值而做各种守护和判断的问题。
- **核心： 统一处理返回值，选择性的提示错误信息。**

## 涉及的第三方框架
> AFNetworking
> 
> Alamofire
> 
> SwiftyJSON
> 
> MJExtension  
>
> SVProgressHUD 

## 请求类型
- 因为项目是一个理财类的app，基本涉及不到DELETE和PUT等其他类型的网络请求，所以这个版本只支持**get**和**post**请求。

## 请求配置
- 这里我采取对象转JSON的方法，我首先封装好两个请求基类**YJBaseRequest**和**YJBaseTableRequest**，里面包含请求路径和分页参数等等。在使用者需要发请求时，如果需要添加其他参数，首先要集成这两个基类中的一个即可，在发请求时，我会把传过来的对象转成对应的请求参数。

## 请求返回值
> 很多时候我们封装框架，会把错误信息一并返回给请求者，其实我觉得这个没有太多的必要，特别是对于一些像未登录而提示的错误，而且要去做相应操作的。我们完全可以在请求完成后统一去过滤和处理就可以了，调用者只需要知道，这次请求是否成功，返回数据是什么就行了。
> 
> 所以我的返回Block只有两个值，一个代表这次请求是否成功的参数**success**，另一个是返回数据OC是id类型的**responseObject**，Swift是SwiftyJSON类型的**JSON**数据。

## 请求方法
为了让外界使用方便，我提供了一个带请求参数和不带请求参数的方法。

### Swift

```objc
/**
       Get方式的网络请求
     * request : 网络请求配置（路径、参数等等）
     * RequestCompletion : 网络回调
     *      success : ture表示此次网络请求成功, 否则失败（false）
     *      JSON    : 返回JSON结构体的数据，有可能为nil
     */
    func get(request: YJBaseRequest, completion: @escaping RequestCompletion) -> () {
        self.printRequestInfo(.get, request)
        self.request(.get, request, completion)
    }
    
    /**
       POST方式的网络请求
     * request : 网络请求配置（路径、参数等等）
     * RequestCompletion : 网络回调
     *      success : ture表示此次网络请求成功, 否则失败（false）
     *      JSON    : 返回JSON结构体的数据，有可能为nil
     */
    func post(request: YJBaseRequest, completion: @escaping RequestCompletion) -> () {
        self.printRequestInfo(.post, request)
        self.request(.post, request, completion)
    }
    
    func get(urlString: String?, completion: @escaping RequestCompletion) -> () {
        let request: YJBaseRequest = YJBaseRequest.init(urlString: urlString ?? "")
        self.printRequestInfo(.get, request)
        self.request(.get, request, completion)
    }
    
    func post(urlString: String?, completion: @escaping RequestCompletion) -> () {
        let request: YJBaseRequest = YJBaseRequest.init(urlString: urlString ?? "")
        self.printRequestInfo(.post, request)
        self.request(.post, request, completion)
    }
```

其中**printRequestInfo**方法是在DEBUG模式下，用来打印请求数据的，方便调试。

## OC

```objc
/**
 Get方式的网络请求
 * request : 网络请求配置（路径、参数等等）
 * CompletionHandler : 网络回调
 *      success : ture表示此次网络请求成功, 否则失败（false）
 *      responseObject : 返回id类型的数据
 */
- (void)get:(YJBaseRequest *)request completion:(CompletionHandler)completion {
    [self logRequestInfoWithType:YJRequestTypeGet request:request];
    [self requestWithType:YJRequestTypeGet request:request completion:completion];
}

/**
 Post方式的网络请求
 * request : 网络请求配置（路径、参数等等）
 * RequestCompletion : 网络回调
 *      success : ture表示此次网络请求成功, 否则失败（false）
 *      responseObject : 返回id类型的数据
 */
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
```
其中**logRequestInfoWithType:request:**方法是在DEBUG模式下，用来打印请求数据的，方便调试。

## 网络请求
### Swift
```objc
// MARK: - <Alamofire>
    private func request(_ type: RequestType, _ request: YJBaseRequest, _ completion: @escaping RequestCompletion) -> () {
        guard request.urlString.characters.count > 0 else {
            #if DEBUGSWIFT
                SVProgressHUD.showInfo(withStatus: "兄弟，你没有设置请求路径。")
            #endif
            completion(false, nil)
            return
        }
        let urlStr: String = String.init(format: "%@%@", YJBaseURLString, request.urlString)

        weak var weakSelf = self
        let method: HTTPMethod = (type == .get ? HTTPMethod.get : HTTPMethod.post)
        let params: Dictionary<String, Any> = request.parameters as! Dictionary<String, Any>
        Alamofire.request(urlStr, method: method, parameters: params, headers: self.httpHeaders()).responseJSON(completionHandler: { (response) in
            
            switch response.result {
            case .success:
                if let value = response.result.value as? [String: AnyObject] {
                    weakSelf?.handleResponseResults(value, response.response, nil, completion)
                } else {
                    weakSelf?.handleResponseResults(nil, response.response, nil, completion)
                }
            case .failure(let error):
                weakSelf?.handleResponseResults(nil, response.response, error, completion)
            }
        })
    }
    
    // MARK: - 统一处理网络请求返回值
    private func handleResponseResults(_ responseObject: Any?, _ httpResponse: HTTPURLResponse?, _ error: Error?, _ completion: @escaping RequestCompletion) -> () {
        YJRequestManager.share().handleResponseResults(withResponse: responseObject, httpResponse: httpResponse, error: error) { (success, responseObject) in
            guard success, responseObject != nil else {
                completion(success, nil)
                return
            }
            let json = JSON(responseObject!)
            completion(true, json)
        }
    }
```

这里Swift调用了OC封装的统一过滤网络请求的方法。


### OC 
```objc
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
```

- 统一处理网络请求返回值

```objc
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

```



## 结尾
> 以上是个人对网络请求的简单理解，如有疑问或建议，欢迎积极留言探讨。>v<

#### 网络请求的完整代码可以在本人的github上下载，你的star就是对作者最大的支持。
- 个人简书: [http://www.jianshu.com/u/b534ce5f8fae](http://www.jianshu.com/u/b534ce5f8fae)
