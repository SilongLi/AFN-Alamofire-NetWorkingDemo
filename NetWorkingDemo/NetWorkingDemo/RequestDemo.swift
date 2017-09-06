//
//  RequestDemo.swift
//  NetWorkingDemo
//
//  Created by lisilong on 17/9/6.
//  Copyright © 2017年 LongShaoDream. All rights reserved.
//

import UIKit

class RequestDemo: NSObject {
    
    static func requestData() -> () {
        let req = YJMessageRequest.init(urlString: "v1.0/app/news/page")
        req?.newsType = "1"
        JYRequestManager.share.post(request: req!) { (success, json) in
            guard success else {
                print("Swift 请求数据失败。")
                return
            }
            print("Swift 请求数据成功。")
        }
    }

}
