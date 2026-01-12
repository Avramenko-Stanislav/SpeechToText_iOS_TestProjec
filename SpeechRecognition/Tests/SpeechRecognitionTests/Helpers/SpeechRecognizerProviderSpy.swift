//
//  SpeechRecognizerProviderSpy.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import SpeechServiceKit
import Speech

final class SpeechRecognizerProviderSpy: SpeechRecognizerProvider, Spy {

  // MARK: - Actions

  enum Action: Equatable {
    case authorizationStatus
    case requestAuthorization
    case isAvailableGet
    case recognitionTask
  }

  // MARK: - Stubs

  nonisolated(unsafe) static var authorizationStatusStub: SFSpeechRecognizerAuthorizationStatus = .notDetermined
  nonisolated(unsafe) static var requestAuthorizationStub: SFSpeechRecognizerAuthorizationStatus = .notDetermined

  var isAvailableStub: Bool = true

  var recognitionTaskStub: SFSpeechRecognitionTask = DummySpeechRecognitionTask()

  // Для удобства проверок в тестах
  private(set) var lastRecognitionRequest: SFSpeechRecognitionRequest?
  private(set) var lastResultHandler: ((SFSpeechRecognitionResult?, Error?) -> Void)?

  // MARK: - SpeechRecognizerProvider

  static func authorizationStatus() -> SFSpeechRecognizerAuthorizationStatus {
    record(.authorizationStatus)
    return authorizationStatusStub
  }

  nonisolated(unsafe) static var onRequestAuthorization: (() -> Void)? = {}

    static func requestAuthorization(_ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void) {
      record(.requestAuthorization)
      onRequestAuthorization?()
      handler(requestAuthorizationStub)
    }

  var isAvailable: Bool {
    record(.isAvailableGet)
    return isAvailableStub
  }

  func recognitionTask(
    with request: SFSpeechRecognitionRequest,
    resultHandler: @escaping (SFSpeechRecognitionResult?, Error?) -> Void
  ) -> SFSpeechRecognitionTask {
    record(.recognitionTask)
    lastRecognitionRequest = request
    lastResultHandler = resultHandler
    return recognitionTaskStub
  }
}
final class DummySpeechRecognitionTask: SFSpeechRecognitionTask {}
