//
//  SpeechRecognizerProvider.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import Speech

public protocol SpeechRecognizerProvider: AnyObject {
  static func authorizationStatus() -> SFSpeechRecognizerAuthorizationStatus
  static func requestAuthorization(_ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void)

  var isAvailable: Bool { get }

  func recognitionTask(
    with request: SFSpeechRecognitionRequest,
    resultHandler: @escaping (SFSpeechRecognitionResult?, Error?) -> Void
  ) -> SFSpeechRecognitionTask
}

extension SFSpeechRecognizer: SpeechRecognizerProvider {}
