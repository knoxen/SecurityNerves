//
//  StopNet.swift
//  StopLight
//
//  Created by Paul Rogers on 10/6/17.
//  Copyright © 2017 Knoxen. All rights reserved.
//

import UIKit

import enum Knoxen.Result
import SwiftyJSON

class StopNet {
  // If accessing a virtual StopLight
  //   - set useStaticHost to true
  //   - set staticHost to the host of the process controlling the virtual StopLight
  // If accessing a StopLight on one or more devices
  //   - set useStaticHost to false
  //   - staticHost value is ignored
  static var useStaticHost = false
  static var staticHost = "localhost"
  
  static let resolveAttempts = 2
  
  enum Intf: String {
    case http, https, srpc
    var name: String {
      return self.rawValue.uppercased()
    }
    var domain: String {
      return "\(self.rawValue).local"
    }
    var port: Int {
      switch self {
      case .http:
        return 4001
      case .https:
        return 4002
      case .srpc:
        return 4003
      }
    }
  }

  enum Status: String {
    case ready, pairing, blocked
  }
  typealias StatusResult = (Result<Status>) -> Void

  struct StopNetResponse {
    public let data: Data
    public let response: URLResponse
  }

  typealias HostResolvedResult = (Result<Bool>) -> Void
  typealias StopNetNameResult = (Result<String>) -> Void

  typealias ContinueCallback = () -> Void
  typealias BoolCallback = (Bool) -> Void
  
  typealias BoolResult = (Result<Bool>) -> Void

  typealias StopNetResult = (Result<StopNetResponse>) -> Void

  typealias StopLightColorResult = (Result<StopLight.Color>) -> Void
  typealias StopLightStatusResult = (Result<StopLight.Status>) -> Void
  typealias StopLightsStatusResult = (Result<[String:JSON]>) -> Void

  typealias JsonMap = [String: String]
  
  fileprivate typealias HostUrlResult = (Result<URL>) -> Void

  let intf: Intf
  
  fileprivate let scheme: String
  fileprivate (set) var hostUrl: URL?
  
  var isHostResolved: Bool {
    return hostUrl != nil
  }
  
  init(intf: Intf, https: Bool = false) {
    self.intf = intf
    scheme = https ? "https" : "http"
  }

  func get(path: String, callback: @escaping StopNetResult) {
    guard isHostResolved else { callback(Result.failure(StopNet.errorReason("Host not resolved"))); return }
    handle(request: createRequest(for: path), callback: callback)
  }
  
  func post(path: String, json: JsonMap, callback: @escaping StopNetResult) {
    guard isHostResolved else { callback(Result.failure(StopNet.errorReason("Host not resolved"))); return }
    handle(request: createRequest(for: path, json: json), callback: callback)
  }

  func handle(request: URLRequest, callback: @escaping StopNetResult) {
    assert(false, "Override method handle in subclasses")
  }
  
  func login(credentials: User.Credentials, callback: @escaping BoolCallback) {
    assert(false, "Override method login in subclasses")
  }

  func pair(credentials: User.Credentials, callback: @escaping BoolCallback) {
    assert(false, "Override method pair in subclasses")
  }

  func deviceStatus(callback: @escaping StopNet.StatusResult) {
    get(path: "device/status") { result in
      switch result {
      case .success(let response):
        let respJson = JSON(response.data)
        if let respStatus = respJson["status"].string, let status = Status(rawValue: respStatus) {
          callback(Result.success(status))
        }
        else {
          callback(Result.failure(StopNet.errorReason("Invalid device status response")))
        }
      case .failure(let error):
        callback(Result.failure(error))
      }
    }
  }
  
  // MARK: -
  func lightsStatus(callback: @escaping StopLightsStatusResult) {
    get(path: "status") { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let stopNetResult):
          let json = JSON(stopNetResult.data)
          if let status = json["status"].dictionary {
            callback(Result.success(status))
          }
          else {
            callback(Result.failure(StopNet.errorReason("Failed parsing StopLight response")))
          }
        case .failure(let error):
          callback(Result.failure(error))
        }
      }
    }
  }
  
  func status(color: StopLight.Color, callback: @escaping StopLightStatusResult) {
    let json = action("status", color: color)
    post(path: "light", json: json) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let stopNetResult):
          let statusString = String(data: stopNetResult.data, encoding: .utf8)!
          let status = StopLight.Status(rawValue: statusString)!
          callback(Result.success(status))
        case .failure(let error):
          callback(Result.failure(error))
        }
      }
    }
  }
  
  func on(color: StopLight.Color, callback: @escaping StopLightColorResult) {
    let json = action("switch", color: color)
    post(path: "light", json: json) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(_):
          callback(Result.success(color))
        case .failure(let error):
          callback(Result.failure(error))
        }
      }
    }
  }
  
  func blink(color: StopLight.Color, callback: @escaping StopLightColorResult) {
    let json = action("blink", color: color)
    post(path: "light", json: json) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(_):
          // CxNote Not actuall checking returned color yet
          callback(Result.success(color))
        case .failure(let error):
          callback(Result.failure(error))
        }
      }
    }
  }
  
  // MARK: - Private -
  func action(_ action: String, color: StopLight.Color) -> StopNet.JsonMap {
    return ["action" : action, "light" : color.rawValue]
  }
  
  internal func createRequest(for path: String, json: JsonMap? = nil) -> URLRequest {
    let requestUrl = URL(string: path, relativeTo: hostUrl!)!
    var request = URLRequest(url: requestUrl)
    if let json = json {
      request.httpMethod = "POST"
      let data = try! JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0))
      request.httpBody = data
    }
    return request
  }

  internal static func userAgent() -> String {
    let clientBundle = Bundle(for: StopNet.self)
    if let info = clientBundle.infoDictionary {
      let version = info["CFBundleShortVersionString"] as! String
      let build = info["CFBundleVersion"] as! String
      let appName = info["CFBundleExecutable"] as! String
      let platform = info["DTSDKName"] as! String
      return "\(appName) \(version).\(build); \(platform)"
    }
    else {
      return "StopNet"
    }
  }
  
  // Each StopLight device broadcast its wifi connection as domain http.local, https.local or
  // srpc.local. If no actual devices are used, set useStaticHost to true and StopNet.staticHost
  // to the static host IP.
  //
  // The following resolve functions discover the IP address of the actual device being
  // controlled by this instance of StopNet.
  func resolveHost(attempt: Int = 0, callback: @escaping HostResolvedResult) {
    guard attempt < StopNet.resolveAttempts else {
      callback(Result.failure(StopNet.errorReason("Failed resolving host \(self)")));
      return
    }
    
    if StopNet.useStaticHost {
      DispatchQueue.main.async {
        self.hostUrl = URL(string: "\(self.scheme)://\(StopNet.staticHost):\(self.intf.port)")
        callback(Result.success(true))
      }
    }
    else {
      resolveHostUrl(attempt) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let url):
            self.hostUrl = url
            print("Resolved \(self.intf.name): \(attempt+1)")
            callback(Result.success(true))
          case .failure(_):
            self.resolveHost(attempt: attempt + 1, callback: callback)
          }
        }
      }
    }
  }

  fileprivate func resolveHostUrl(_ attempt: Int, callback: HostUrlResult) {
    let domain = intf.domain as CFString
    print("Attempt \(attempt+1) for \(domain as String)")
    let host = CFHostCreateWithName(nil, domain).takeRetainedValue()
    CFHostStartInfoResolution(host, .addresses, nil)
    var success: DarwinBoolean = false
    if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
      let address = addresses.firstObject as? NSData {
      var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
      if getnameinfo(address.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(address.length),
                     &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
        let ipAddr = String(cString: hostname)
        if let url = URL(string: "\(scheme)://\(ipAddr):\(intf.port)") {
          callback(Result.success(url))
        }
        else {
          callback(Result.failure(StopNet.errorReason("Failed forming host URL form IP addr: \(ipAddr)")))
        }
      }
      else {
        callback(Result.failure(StopNet.errorReason("Failed getnameinfo call")))
      }
    }
    else {
      callback(Result.failure(StopNet.errorReason("Failed CF host addressing")))
    }
  }
  
  // MARK: - Static -
  
  static func errorReason(_ message: String) -> Error {
    let userInfo = [NSLocalizedDescriptionKey : message]
    return NSError(domain: "com.knoxen.StopLight", code: 0, userInfo: userInfo)
  }

  static func invalidLogin(callback: @escaping ContinueCallback = {}) {
    DispatchQueue.main.async {
      let title = "Invalid Login"
      let message = ""
      let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      
      let okAction = UIAlertAction(title: "OK", style: .default) { _ in
        callback()
      }
      alertController.addAction(okAction)
      
      // Fragile, but this is demo quality code
      UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
  }

  static func blocked(callback: @escaping BoolResult) {
    DispatchQueue.main.async {
      let title = "Device Blocked"
      let message = "Put your device in pairing mode to set the Username/Password"
      let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      
      let okAction = UIAlertAction(title: "OK", style: .default) { _ in
        callback(Result.success(false))
      }
      alertController.addAction(okAction)
      
      // Fragile, but this is demo quality code
      UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
  }

}
