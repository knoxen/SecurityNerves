//
//  HttpsNet.swift
//  StopLight
//
//  Created by Paul Rogers on 10/6/17.
//  Copyright © 2017 Knoxen. All rights reserved.
//

import Foundation

class HttpsNet: HttpNet {
  
  override init() {
    super.init(intf: .https, https: true)
  }
}
