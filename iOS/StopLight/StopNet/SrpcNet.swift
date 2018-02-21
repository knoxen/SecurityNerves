//
//  SrpcNet.swift
//  StopLight
//
//  Created by Paul Rogers on 10/6/17.
//  Copyright © 2017 Knoxen. All rights reserved.
//

import Foundation

import Knoxen
import SwiftyJSON

import enum Knoxen.Result

class SrpcNet: StopNet {
  
  var knoxen: Knoxen!
  var libClient:  Client?
  var userClient: Client?
  
  init() {
    super.init(intf: .srpc)
  }

  override func resolveHost(attempt: Int, callback: @escaping StopNet.HostResolvedResult) {
    super.resolveHost(attempt: attempt) { result in
      if result.successful {
        self.knoxen = Knoxen(url: self.hostUrl!)
        self.knoxen.config.nonceSize = 4
        self.knoxen.config.retry = true
      }
      callback(result)
    }
  }
  
  override func handle(request: URLRequest, callback: @escaping StopNetResult) {
    if let client = userClient {
      handle(request: request, with: client, callback: callback)
    }
    else if let client = libClient {
      handle(request: request, with: client, callback: callback)
    }
    else {
      libClient { clientResult in
        switch clientResult {
        case .success(let client):
          self.libClient = client
          self.handle(request: request, with: client, callback: callback)
        case .failure(let error):
          callback(Result.failure(error))
        }
      }
    }
  }
  
  fileprivate func handle(request: URLRequest, with client: Client, callback: @escaping StopNetResult) {
    client.handle(request: request) { srpcResult in
      switch srpcResult {
      case .success(let respResult):
        let stopNetResult = StopNetResponse(data: respResult.data, response: respResult.response)
        callback(Result.success(stopNetResult))
      case .failure(let error):
        callback(Result.failure(error))
      }
    }
  }
  
  override func login(credentials: User.Credentials, callback: @escaping BoolCallback) {
    libClient { result in
      switch result {
      case .success(let libClient):
        libClient.userClient(username: credentials.username, password: credentials.password) { result in
          switch result {
          case .success(let client):
            self.userClient = client
            libClient.close()
            self.libClient = nil
            callback(true)
          case .failure(let error):
            print("Error: \(error)")
            callback(false)
          }
        }
      case .failure(let error):
        print("Error: \(error)")
        callback(false)
      }
    }
  }

  override func pair(credentials: User.Credentials, callback: @escaping BoolCallback) {
    libClient { result in
      switch result {
      case .success(let libClient):
        libClient.register(username: credentials.username, password: credentials.password) { result in
          switch result {
          case .success(let registration):
            if registration.code == .ok {
              self.login(credentials: credentials, callback: callback)
            }
            else {
              print("Invalid SRPC registration")
              callback(false)
            }
          case .failure(let error):
            print("Error: \(error)")
            callback(false)
          }
        }
      case .failure(let error):
        print("Error: \(error)")
        callback(false)
      }
    }
  }
  
  fileprivate func libClient(callback: @escaping ClientCallback) {
    if let libClient = self.libClient {
      callback(Result.success(libClient))
    }
    else {
      knoxen.libClient { result in
        switch result {
        case .success(let client):
          self.libClient = client
          callback(Result.success(client))
        case .failure(let error):
          callback(Result.failure(error))
        }
      }
    }
  }
}
