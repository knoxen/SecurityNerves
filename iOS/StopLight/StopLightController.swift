//
//  StopLighController.swift
//  StopLight
//
//  Created by Paul Rogers on 10/6/17.
//  Copyright © 2017 Knoxen. All rights reserved.
//

import UIKit

import GestureRecognizerClosures
import PKHUD

class StopLightController: UIViewController {

  @IBOutlet weak var stopNetSegmentedControl: UISegmentedControl!
  
  @IBOutlet weak var redLightView: UIView!
  @IBOutlet weak var yellowLightView: UIView!
  @IBOutlet weak var greenLightView: UIView!
  
  enum Segment: Int {
    case http  = 0
    case https = 1
    case srpc  = 2
    
    static func segment(stopNet: StopNet) -> Segment {
      switch stopNet.intf {
      case .http:
        return Segment.http
      case .https:
        return Segment.https
      case .srpc:
        return Segment.srpc
      }
    }
  }
  
  @IBAction func stopNetChange(_ control: UISegmentedControl) {
    connect(intf: Segment(rawValue: control.selectedSegmentIndex)!)
  }

  var redLight:    StopLight!
  var yellowLight: StopLight!
  var greenLight:  StopLight!
  
  var stopLight: StopLight!
  
  var httpNet:  HttpNet!
  var httpsNet: HttpsNet!
  var srpcNet:  SrpcNet!
  
  var stopNet: StopNet!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    stopNetSegmentedControl.selectedSegmentIndex = -1
    
    redLight    = StopLight(redLightView, .red)
    yellowLight = StopLight(yellowLightView, .yellow)
    greenLight  = StopLight(greenLightView, .green)
    
    setup(redLight)
    setup(yellowLight)
    setup(greenLight)

    httpNet  = HttpNet()
    httpsNet = HttpsNet()
    srpcNet  = SrpcNet()

    resolveHosts()
  }

  fileprivate func connect(intf: Segment) {
    if let currentLight = stopLight {
      currentLight.off()
    }
    
    switch intf {
    case .http:
      stopNet = httpNet
    case .https:
      stopNet = httpsNet
    case .srpc:
      stopNet = srpcNet
    }
    
    stopNet.deviceStatus { result in
      switch result {
      case .success(let status):
        switch status {
        case .ready:
          self.login()
        case .pairing:
          self.pair()
        case .blocked:
          self.reject("blocked")
          StopNet.blocked { _ in }
        }
      case .failure(let error):
        self.reject("Failed to obtain device status: \(error)")
      }
    }
  }
  
  fileprivate func login() {
    User.credentials(stopNet: stopNet) { result in
      switch result {
      case .success(let credentials):
        self.login(credentials)
      case .failure(let error):
        self.reject("Login error: \(error.localizedDescription)")
      }
    }
  }
  
  fileprivate func login(_ credentials: User.Credentials) {
    self.stopNet.login(credentials: credentials) { result in
      if result {
        self.lightsStatus()
      }
      else {
        self.reject("Invalid login")
        StopNet.invalidLogin()
      }
    }
  }
  
  fileprivate func pair() {
    User.credentials(stopNet: stopNet) { result in
      switch result {
      case .success(let credentials):
        self.stopNet.pair(credentials: credentials) { result in
          if result {
            self.login(credentials)
          }
          else {
            self.reject("Unable to pair")
          }
        }
      case .failure(let error):
        self.reject("Error while pairing: \(error.localizedDescription)")
      }
    }
  }
  
  fileprivate func lightsStatus() {
    stopNet.lightsStatus { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let status):
          [self.redLight, self.yellowLight, self.greenLight].forEach { light in
            if let light = light {
              let color = light.color.rawValue
              switch status[color]!.stringValue {
              case "on":
                light.on()
              case "off":
                light.off()
              case "blinking":
                light.blink()
              default:
                light.off()
              }
            }
          }
          let light = status["light"]!.stringValue
          self.setStopLight(StopLight.Color(rawValue: light)!)
        case .failure(let error):
          self.reject("status error: \(error)")
        }
      }
    }
  }

  fileprivate func clearLights() {
    redLight.off()
    yellowLight.off()
    greenLight.off()
  }
  
  fileprivate func setStopLight(_ color: StopLight.Color) {
    switch color {
    case .red:
      stopLight = redLight
    case .yellow:
      stopLight = yellowLight
    case .green:
      stopLight = greenLight
    }
  }
  
  fileprivate func reject(_ message: String) {
    print("Reject: \(message)")
    self.stopNetSegmentedControl.selectedSegmentIndex = -1
  }
  
  fileprivate func setup(_ stopLight: StopLight) {

    stopLight.view.onTap { _ in
      guard !stopLight.isOn() else { return }
      if let stopNet = self.stopNet {
        stopNet.on(color: stopLight.color) { result in
          DispatchQueue.main.async {
            switch result {
            case .success(_):
              self.stopLight?.off()
              stopLight.on()
              self.stopLight = stopLight
            case .failure(let error):
              print("Failed to turn on color \(stopLight.color): \(error)")
            }
          }
        }
      }
    }
    
    stopLight.view.onDoubleTap {_ in
      guard !stopLight.isBlinking() else { return }
      if let stopNet = self.stopNet {
        stopNet.blink(color: stopLight.color) { result in
          DispatchQueue.main.async {
            switch result {
            case .success(_):
              self.stopLight?.off()
              stopLight.blink()
              self.stopLight = stopLight
            case .failure(let error):
              print("Failed to blink color \(stopLight.color): \(error)")
            }
          }
        }
      }
    }
  }

  fileprivate func resolveHosts() {
    let hud = PKHUDProgressView(title: "StopLights", subtitle: "Searching")
    DispatchQueue.main.async {
      PKHUD.sharedHUD.contentView = hud
      PKHUD.sharedHUD.show()
    }
    
    let stopNets = [httpNet, httpsNet, srpcNet] as [StopNet]
    DispatchQueue.global(qos: .utility).async {
      let group = DispatchGroup()
      for stopNet in stopNets {
        group.enter()
        DispatchQueue.global(qos: .utility).async {
          stopNet.resolveHost { result in
            DispatchQueue.main.async {
              let segment = Segment.segment(stopNet: stopNet).rawValue
              self.stopNetSegmentedControl.setTitle(stopNet.intf.name, forSegmentAt: segment)
              switch result {
              case .success(_):
                self.stopNetSegmentedControl.setEnabled(true, forSegmentAt: segment)
              case .failure(let error):
                print("\(error)")
              }
            }
            group.leave()
          }
        }
      }
      group.wait()
      DispatchQueue.main.async {
        let titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.red]
        self.stopNetSegmentedControl.setTitleTextAttributes(titleTextAttributes, for: .disabled)
        
        var ok = true
        for ndx in 0 ..< self.stopNetSegmentedControl.numberOfSegments {
          ok = ok && self.stopNetSegmentedControl.isEnabledForSegment(at: ndx)
        }
        if ok {
          HUD.flash(.success, delay: 0.5)
        }
        else {
          HUD.flash(.error, delay: 0.5)
        }
      }
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}

extension String: Error {}
