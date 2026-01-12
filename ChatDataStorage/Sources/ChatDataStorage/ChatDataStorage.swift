// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public protocol ChatDataStorageService: AnyObject, Sendable {}

public final class ChatDataStorageManager: ChatDataStorageService {
  public init() {}
}
