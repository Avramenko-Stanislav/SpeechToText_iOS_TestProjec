//
//  LiveSpeechService.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import Foundation

public protocol SpeechTranscriberService: Actor {}

public actor SpeechTranscriberManager: SpeechTranscriberService {
  public init() {}
}
