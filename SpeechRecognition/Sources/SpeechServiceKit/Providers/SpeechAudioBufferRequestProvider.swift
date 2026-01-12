//
//  SpeechAudioBufferRequestProvider.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import AVFAudio
import Speech

public protocol SpeechAudioBufferRequestProvider: AnyObject {
  var shouldReportPartialResults: Bool { get set }

  var requiresOnDeviceRecognition: Bool { get set }

  func append(_ buffer: AVAudioPCMBuffer)
  func endAudio()
}

extension SFSpeechAudioBufferRecognitionRequest: SpeechAudioBufferRequestProvider {}
