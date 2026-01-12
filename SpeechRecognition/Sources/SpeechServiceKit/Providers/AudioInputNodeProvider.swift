//
//  AudioInputNodeProvider.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import AVFAudio

public protocol AudioInputNodeProvider: AnyObject {
  func outputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat

  func installTap(
    onBus bus: AVAudioNodeBus,
    bufferSize: AVAudioFrameCount,
    format: AVAudioFormat?,
    block: @escaping AVAudioNodeTapBlock
  )

  func removeTap(onBus bus: AVAudioNodeBus)
}

extension AVAudioInputNode: AudioInputNodeProvider {}
