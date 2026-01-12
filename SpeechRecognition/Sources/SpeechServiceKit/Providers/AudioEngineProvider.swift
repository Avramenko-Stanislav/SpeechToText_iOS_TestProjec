//
//  AudioEngineProvider.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import AVFAudio

public protocol AudioEngineProvider: AnyObject {
  var inputNode: AVAudioInputNode { get }
  var isRunning: Bool { get }

  func prepare()
  func start() throws
  func stop()
}

extension AVAudioEngine: AudioEngineProvider {}
