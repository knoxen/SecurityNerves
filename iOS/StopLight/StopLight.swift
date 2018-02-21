//
//  StopLight.swift
//  BareStopLight
//
//  Created by Paul Rogers on 9/30/17.
//  Copyright © 2017 Knoxen. All rights reserved.
//

import UIKit

import SwiftyTimer

class StopLight: Equatable {
  static let blinkRate = 0.5.seconds
  
  enum Color: String {
    case red, yellow, green
  }

  enum Status: String {
    case off = "off"
    case on = "on"
    case blinkOn = "blinking"
    case blinkOff = "blinking off"
  }
  static let dim: CGFloat = 0.25
  static let bright: CGFloat = 1.0

  let view: UIView
  let color: Color
  var status: Status
  
  var blinkTimer: Timer?
  
  init(_ view: UIView, _ color: Color) {
    let side = view.bounds.size.height

    let layer = view.layer
    layer.cornerRadius = side/2
    layer.borderWidth = 3
    view.alpha = StopLight.dim

    self.view = view
    self.color = color
    self.status = .off
  }
  
  func on() {
    stop()
    guard status != .on else { return }
    status = .on
    view.alpha = StopLight.bright
  }
  
  func off() {
    stop()
    guard status != .off else { return }
    status = .off
    view.alpha = StopLight.dim
  }
  
  func blink() {
    guard !isBlinking() else { return }

    status = .blinkOff
    view.alpha = StopLight.dim
    Timer.every(StopLight.blinkRate) { timer in
      self.blinkTimer = timer
      if self.isBlinking() {
        if self.status == .blinkOn {
          self.status = .blinkOff
          self.view.alpha = StopLight.dim
        }
        else {
          self.status = .blinkOn
          self.view.alpha = StopLight.bright
        }
      }
      else {
        self.stop()
      }
    }
  }
  
  func stop() {
    self.blinkTimer?.invalidate()
    self.blinkTimer = nil
  }
  
  func isOn() -> Bool { return status == .on }
  func isOff() -> Bool { return status == .off }
  func isBlinking() -> Bool { return status == .blinkOn || status == .blinkOff }
  
  public static func ==(lhs: StopLight, rhs: StopLight) -> Bool {
    return lhs.view == rhs.view
  }
}
