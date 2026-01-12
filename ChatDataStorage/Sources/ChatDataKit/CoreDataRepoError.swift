//
//  CoreDataRepoError.swift
//  ChatDataStorage
//
//  Created by Stanislav on 12.01.2026.
//

import Foundation

public enum CoreDataRepoError: LocalizedError {
  case storesNotLoaded
  case invalidChatID
  case textMissing
    case chatNotFound(String)

  public var errorDescription: String? {
      switch self {
      case .textMissing:
        return "Text is empty to save"
      case .storesNotLoaded:
        return "Core Data stores are not loaded yet."
      case .invalidChatID:
        return "Chat ID is invalid."
      case .chatNotFound(let id):
        return "Chat not found (id: \(id))."
      }
    }
}
