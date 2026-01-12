//
//  PermissionGateService.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import Foundation

public protocol PermissionGateService: Actor {
  func joinOrBecomeOwner() async -> Result<Void, Error>?
  func complete(_ result: Result<Void, Error>)
}

public actor PermissionGateServiceImpl: PermissionGateService {
  private var running = false
  private var waiters: [CheckedContinuation<Result<Void, Error>, Never>] = []

  public init(running: Bool = false, waiters: [CheckedContinuation<Result<Void, Error>, Never>] = []) {
    self.running = running
    self.waiters = waiters
  }

  public func joinOrBecomeOwner() async -> Result<Void, Error>? {
    if running {
      return await withCheckedContinuation { cont in
        waiters.append(cont)
      }
    } else {
      running = true
      return nil
    }
  }

  public func complete(_ result: Result<Void, Error>) {
    running = false
    let current = waiters
    waiters.removeAll()
    for cont in current {
      cont.resume(returning: result)
    }
  }
}
