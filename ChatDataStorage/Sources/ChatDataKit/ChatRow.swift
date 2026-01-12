//
//  ChatRow.swift
//  ChatDataStorage
//
//  Created by Stanislav on 12.01.2026.
//

import Foundation

public struct ChatRow: Identifiable, Hashable, Sendable {
  public let id: String
  public let title: String
  public let lastMessagePreview: String?
  public let updatedAt: Date

  public init(id: String, title: String, lastMessagePreview: String?, updatedAt: Date) {
    self.id = id
    self.title = title
    self.lastMessagePreview = lastMessagePreview
    self.updatedAt = updatedAt
  }
}
