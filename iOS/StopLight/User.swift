//
//  User.swift
//  StopLight
//
//  Created by Paul Rogers on 11/5/17.
//  Copyright © 2017 Knoxen. All rights reserved.
//

import Foundation

import PKHUD
import enum Knoxen.Result

class User {
  
  struct Credentials {
    let username: String
    let password: String
  }
  
  typealias CredentialsResult = (Result<Credentials>) -> Void
  
  static func credentials(stopNet: StopNet, callback: @escaping CredentialsResult) {
    DispatchQueue.main.async {
      let title = "\(stopNet.intf.name) Login"
      let message = "So who are you?"
      let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      
      let confirmAction = UIAlertAction(title: "Submit", style: .default) { _ in
        let username = alertController.textFields![0].text!
        let password = alertController.textFields![1].text!
        let credentials = Credentials(username: username, password: password)
        callback(Result.success(credentials))
      }
      
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
        let error = StopNet.errorReason("Login cancelled by user")
        callback(Result.failure(error))
      }
      
      alertController.addTextField { textField in
        textField.font = UIFont.boldSystemFont(ofSize: 22)
        textField.placeholder = "Username"
      }
      alertController.addTextField { textField in
        textField.font = UIFont.boldSystemFont(ofSize: 22)
        textField.placeholder = "Password"
        textField.isSecureTextEntry = true
      }
      
      alertController.addAction(confirmAction)
      alertController.addAction(cancelAction)
      
      // Fragile, but this is demo quality code
      UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
  }
  
}
