//
//  SpeechRecognitionTaskProvider.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import Speech

public protocol SpeechRecognitionTaskProvider: AnyObject {
  func cancel()
}
extension SFSpeechRecognitionTask: SpeechRecognitionTaskProvider {}
