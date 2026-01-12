//
//  SpeechAccess.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import Foundation

public enum SpeechAccess: Equatable {
  case ready
  case needsRequest
  case denied(message: String, canOpenSettings: Bool)
  case restricted(message: String)
}
