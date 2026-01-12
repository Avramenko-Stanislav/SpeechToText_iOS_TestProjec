//
//  SpyKeys.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//


import Foundation
import ObjectiveC

private enum SpyKeys {
  nonisolated(unsafe) static let recordedActions = malloc(1)!
}

// MARK: - Spy

public protocol Spy: AnyObject {
  associatedtype Action: Equatable

  func reset()
  static func reset()
}

extension Spy {
  public static var recordedActions: [Action] {
    if let actions = objc_getAssociatedObject(self, SpyKeys.recordedActions) as? [Action] {
      return actions
    }

    return []
  }

  public var recordedActions: [Action] {
    if let actions = objc_getAssociatedObject(self, SpyKeys.recordedActions) as? [Action] {
      return actions
    }

    return []
  }

  public static func record(_ action: Action) {
    set(actions: recordedActions + [action])
  }

  public static func reset() {
    set(actions: nil)
  }

  public static func set(actions: [Action]?) {
    objc_setAssociatedObject(
      self,
      SpyKeys.recordedActions,
      actions,
      objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }

  public func record(_ action: Action) {
    set(actions: recordedActions + [action])
  }

  public func reset() {
    set(actions: nil)
  }

  public func set(actions: [Action]?) {
    objc_setAssociatedObject(
      self,
      SpyKeys.recordedActions,
      actions,
      objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
  }
}
