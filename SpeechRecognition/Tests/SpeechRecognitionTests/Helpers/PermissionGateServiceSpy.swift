//
//  PermissionGateServiceSpy.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import SpeechRecognition

public actor PermissionGateServiceSpy: PermissionGateService {

  public enum Action: Sendable, Equatable {
    case joinOrBecomeOwner
    case completeSuccess
    case completeFailure(String)
  }

  private var actions: [Action] = []

  private var running: Bool
  private var waiters: [CheckedContinuation<Result<Void, Error>, Never>] = []

  public private(set) var lastComplete: Result<Void, Error>?

  public init(running: Bool = false) {
    self.running = running
  }

  // MARK: - PermissionGateService

  public func joinOrBecomeOwner() async -> Result<Void, Error>? {
    actions.append(.joinOrBecomeOwner)

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
    lastComplete = result

    switch result {
    case .success:
      actions.append(.completeSuccess)
    case .failure(let error):
      actions.append(.completeFailure(String(describing: error)))
    }

    running = false
    let current = waiters
    waiters.removeAll(keepingCapacity: true)
    for cont in current {
      cont.resume(returning: result)
    }
  }

  // MARK: - Test helpers

  public func recordedActions() -> [Action] { actions }

  public func reset() {
    actions.removeAll(keepingCapacity: true)
    running = false
    waiters.removeAll(keepingCapacity: true)
    lastComplete = nil
  }

  public func setRunning(_ value: Bool) {
    running = value
  }

  public func isRunning() -> Bool { running }
  public func waiterCount() -> Int { waiters.count }
}
