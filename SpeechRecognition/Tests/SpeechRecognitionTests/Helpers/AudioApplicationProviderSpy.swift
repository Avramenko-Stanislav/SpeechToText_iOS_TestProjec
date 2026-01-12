//
//  AudioApplicationProviderSpy.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import AVFAudio
import SpeechServiceKit

final class AudioApplicationProviderSpy: AudioApplicationProvider, Spy {

  var recordPermission: AVAudioApplication.recordPermission {
    record(.recordPermissionCall)
    return recordPermissionStub
  }

  var recordPermissionStub: AVAudioApplication.recordPermission = .denied

  enum Action: Equatable {
    case recordPermissionCall
  }

}
