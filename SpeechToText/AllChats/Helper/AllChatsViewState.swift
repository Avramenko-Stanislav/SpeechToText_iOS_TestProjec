//
//  AllChatsViewState.swift
//  Speech to text
//
//  Created by Stanislav on 12.01.2026.
//

import Foundation
import ChatDataKit

enum AllChatsViewState: Equatable {
  case idle
  case isLoading
  case onSuccess(rows: [ChatRow])
  case onError(message: String)

  var isLoading: Bool {
    self == .isLoading
  }
}
