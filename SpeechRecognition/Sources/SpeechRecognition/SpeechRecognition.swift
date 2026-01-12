// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

@MainActor
public protocol SpeechPermissionsService: AnyObject {}

@MainActor
public final class SpeechPermissionsManager: SpeechPermissionsService {
  public init() {}
}
