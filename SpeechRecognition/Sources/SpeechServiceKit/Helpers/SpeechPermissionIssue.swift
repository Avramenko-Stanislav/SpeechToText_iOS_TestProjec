//
//  SpeechPermissionIssue.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import Foundation
import Speech

public enum SpeechPermissionIssue: Error, LocalizedError, Equatable {
  case microphoneDenied
  case speechDenied(SFSpeechRecognizerAuthorizationStatus)
  case speechRestricted
  case denied

  public var errorDescription: String? {
    switch self {
    case .microphoneDenied:
      return "Microphone access is denied. Enable it in Settings."
    case .speechDenied:
      return "Speech recognition access is denied. Enable it in Settings."
    case .speechRestricted:
      return "Speech recognition is restricted by the system (Screen Time/MDM)."
    case .denied:
      return "Recording and speech recognition access is denied."
    }
  }

  public var canOpenSettings: Bool {
    switch self {
    case .speechRestricted: return false
    default: return true
    }
  }
}
