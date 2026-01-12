//
//  AudioSessionProvider.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import AVFAudio

public protocol AudioSessionProvider {
  var recordPermission: AVAudioSession.RecordPermission { get }

  func requestRecordPermission(_ response: @escaping (Bool) -> Void)
  func setCategory(
      _ category: AVAudioSession.Category,
      mode: AVAudioSession.Mode,
      options: AVAudioSession.CategoryOptions
    ) throws
    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws
}

extension AVAudioSession: AudioSessionProvider {}
