//
//  HttpNet.swift
//  StopLight
//
//  Created by Paul Rogers on 10/9/17.
//  Copyright © 2017 Knoxen. All rights reserved.
//

import Foundation

import SwiftyJSON

import enum Knoxen.Result

class HttpNet: StopNet {
  
  init() {
    super.init(intf: .http)
  }
  
  override init(intf: Intf, https: Bool = false) {
    super.init(intf: intf, https: https)
  }

  override func login(credentials: User.Credentials, callback: @escaping BoolCallback) {
    self.action("login", with: credentials, callback: callback)
  }
  
  override func pair(credentials: User.Credentials, callback: @escaping BoolCallback) {
    self.action("pair", with: credentials, callback: callback)
  }
  
  func action(_ action: String, with credentials: User.Credentials, callback: @escaping BoolCallback) {
    let json = ["username" : credentials.username, "password" : credentials.password]
    post(path: action, json: json) { result in
      switch result {
      case .success(let response):
        let respJson = JSON(response.data)
        callback(respJson["status"].stringValue == "ok")
      case .failure(let error):
        print("Error: \(error)")
        callback(false)
      }
    }
  }
  
  override func handle(request: URLRequest, callback: @escaping StopNetResult) {
    let session = createSession(for: request.httpMethod!)
    session.dataTask(with: request) { data, response, error in
      if let data = data, let response = response as? HTTPURLResponse {
        if 200...299 ~= response.statusCode {
          callback(Result.success(StopNetResponse(data: data, response: response)))
        }
        else {
          callback(Result.failure(StopNet.errorReason("Status code: #{response.statusCode}")))
        }
      }
      else {
        callback(Result.failure(error!))
      }
    }.resume()
  }
  
  fileprivate func createSession(for method: String) -> URLSession {
    let contentType = method == "GET" ? "text/plain" : "application/json"
    let sessionConfig = URLSessionConfiguration.ephemeral
    sessionConfig.timeoutIntervalForRequest = 15
    sessionConfig.httpAdditionalHeaders = ["Content-Type" : contentType,
                                           "User-Agent" : StopNet.userAgent()]
    return URLSession.init(configuration: sessionConfig)
  }
  
}
