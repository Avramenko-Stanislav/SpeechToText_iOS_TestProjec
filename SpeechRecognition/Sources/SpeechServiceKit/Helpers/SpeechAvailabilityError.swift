//
//  SpeechAvailabilityError.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import Foundation

public enum SpeechAvailabilityError: LocalizedError {
  case recognizerUnavailable
  case onDeviceNotSupported

  public var errorDescription: String? {
    switch self {
    case .recognizerUnavailable:
      return "Speech recognizer is not available"
    case .onDeviceNotSupported:
      return "On-device speech recognition is not available on this device"
    }
  }
}
