//
//  AudioApplicationProvider.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import AVFAudio

public protocol AudioApplicationProvider {
  var recordPermission: AVAudioApplication.recordPermission { get }
}
extension AVAudioApplication: AudioApplicationProvider {}
