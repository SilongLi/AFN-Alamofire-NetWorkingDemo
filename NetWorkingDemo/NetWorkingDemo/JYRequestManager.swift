//
//  JYRequestManager.swift
//  YaoJiFinancing
//
//  Created by lisilong on 17/8/5.
//  Copyright © 2017年 ainuolun. All rights reserved.
//

import UIKit
import Alamofire
import SVProgressHUD
import SwiftyJSON


class JYRequestManager: NSObject {
    
    enum RequestType {
        case get
        case post
    }
    
    typealias RequestCompletion = (Bool, JSON?) -> ()
    
    static let share = JYRequestManager.init()
    private override init() {
        super.init()
    }
}

extension JYRequestManager {
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
                    weakSelf?.handleResponseResults(value, nil, completion)
                } else {
                    weakSelf?.handleResponseResults(nil, nil, completion)
                }
            case .failure(let error):
                weakSelf?.handleResponseResults(nil, error, completion)
            }
        })
    }
    
    // MARK: - 统一处理网络请求返回值
    private func handleResponseResults(_ responseObject: Any?, _ error: Error?, _ completion: @escaping RequestCompletion) -> () {
        YJRequestManager.share().handleResponseResults(withResponse: responseObject, error: error) { (success, responseObject) in
            guard success, responseObject != nil else {
                completion(success, nil)
                return
            }
            let json = JSON(responseObject!)
            completion(true, json)
        }
    }
    
    // MARK: - setup http headers
    private func httpHeaders() -> (HTTPHeaders) {
        return [
            "version"       :   Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            "sdkVersion"    :   UIDevice.current.systemVersion,
            "platform"      :   "4",
            "Accept"        :   "application/json",
        ]
    }
    
    // MARK: - 打印网络请求日志
    private func printRequestInfo(_ type: RequestType, _ request: YJBaseRequest) -> () {
        let method = (type == .get ? "GET" : "POST")
        print(NSString.init(format: "\n\n  type:%@\n  Url: %@%@\n  params: %@\n%@\n\n", method, YJBaseURLString , request.urlString ?? "", request.parameters, self.httpHeaders()))
    }
    
}

