//
//  AudioSessionProviderSpy.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import SpeechServiceKit
import AVFAudio

final class AudioSessionProviderSpy: AudioSessionProvider, Spy {

  enum Action: Equatable {
    case setActive(active: Bool, options: AVAudioSession.SetActiveOptions)
    case setCategory(category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)
    case requestRecordPermission
    case recordPermission
  }

  // MARK: - Stubs

  var recordPermissionStub: AVAudioSession.RecordPermission = .denied
  var requestRecordPermissionResultStub: Bool = false
  var requestRecordPermissionStub: (@escaping (Bool) -> Void) -> Void = { _ in }
  var setCategoryErrorStub: Error?
  var setActiveErrorStub: Error?

  // MARK: - AudioSessionProvider

  var recordPermission: AVAudioSession.RecordPermission {
    record(.recordPermission)
    return recordPermissionStub
  }

  func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
    record(.requestRecordPermission)
    requestRecordPermissionStub(response)
  }

  func setCategory(
    _ category: AVAudioSession.Category,
    mode: AVAudioSession.Mode,
    options: AVAudioSession.CategoryOptions
  ) throws {
    record(.setCategory(category: category, mode: mode, options: options))
    if let error = setCategoryErrorStub { throw error }
  }

  func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
    record(.setActive(active: active, options: options))
    if let error = setActiveErrorStub { throw error }
  }
}
