import Foundation
import SpeechServiceKit
import AVFAudio
import Speech

@MainActor
public protocol SpeechPermissionsService: AnyObject {
  func currentAccess() -> SpeechAccess
  func requestIfNeeded() async -> SpeechAccess
}

@MainActor
public final class SpeechPermissionsManager: SpeechPermissionsService {
  private let permissionGate: PermissionGateService
  private let audioApplication: AudioApplicationProvider
  private let audioSession: AudioSessionProvider
  private let speechRecognizer: SpeechRecognizerProvider.Type

  public init(
    permissionGate: PermissionGateService = PermissionGateServiceImpl(),
    audioApplication: AudioApplicationProvider = AVAudioApplication.shared,
    audioSession: AudioSessionProvider = AVAudioSession.sharedInstance(),
    speechRecognizer: SpeechRecognizerProvider.Type = SFSpeechRecognizer.self
  ) {
    self.permissionGate = permissionGate
    self.audioApplication = audioApplication
    self.audioSession = audioSession
    self.speechRecognizer = speechRecognizer
  }

  public func currentAccess() -> SpeechAccess {
    let microphone = audioApplication.recordPermission
    let speech = speechRecognizer.authorizationStatus()

    if speech == .restricted {
      return .restricted(message: SpeechPermissionIssue.speechRestricted.localizedDescription)
    } else if microphone == .denied {
      return .denied(
        message: SpeechPermissionIssue.microphoneDenied.localizedDescription,
        canOpenSettings: true
      )
    } else if speech == .denied {
      return .denied(
        message: SpeechPermissionIssue.speechDenied(speech).localizedDescription,
        canOpenSettings: true
      )
    } else if microphone == .undetermined || speech == .notDetermined {
      return .needsRequest
    }

    return (microphone == .granted && speech == .authorized) ? .ready : .needsRequest
  }

  public func requestIfNeeded() async -> SpeechAccess {
    switch currentAccess() {
    case .ready:
      return .ready
    case .denied(let m, let can):
      return .denied(message: m, canOpenSettings: can)
    case .restricted(let m):
      return .restricted(message: m)
    case .needsRequest:
      break
    }

    if let joined = await permissionGate.joinOrBecomeOwner() {
      return mapResultToAccess(joined)
    }

    let final: Result<Void, Error>
    do {
      try await requestMicrophoneIfNeeded()
      try await requestSpeechIfNeeded()
      final = .success(())
    } catch {
      final = .failure(error)
    }

    await permissionGate.complete(final)
    return mapResultToAccess(final)
  }

  private func mapResultToAccess(_ result: Result<Void, Error>) -> SpeechAccess {
    switch result {
    case .success:
      return currentAccess()

    case .failure(let error as SpeechPermissionIssue):
      if error == .speechRestricted {
        return .restricted(message: error.localizedDescription)
      } else {
        return .denied(message: error.localizedDescription, canOpenSettings: error.canOpenSettings)
      }

    case .failure(let error):
      return .denied(message: error.localizedDescription, canOpenSettings: true)
    }
  }

  private func requestMicrophoneIfNeeded() async throws {
    let session = audioSession

    switch session.recordPermission {
    case .granted:
      return

    case .denied:
      throw SpeechPermissionIssue.microphoneDenied

    case .undetermined:
      let granted = await withCheckedContinuation { continuation in
        session.requestRecordPermission { continuation.resume(returning: $0) }
      }
      guard granted else { throw SpeechPermissionIssue.microphoneDenied }

    @unknown default:
      throw SpeechPermissionIssue.microphoneDenied
    }
  }

  private func requestSpeechIfNeeded() async throws {
    switch speechRecognizer.authorizationStatus() {
    case .authorized:
      return

    case .denied:
      throw SpeechPermissionIssue.speechDenied(.denied)

    case .restricted:
      throw SpeechPermissionIssue.speechRestricted

    case .notDetermined:
      let status = await withCheckedContinuation { continuation in
        speechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
      }

      switch status {
      case .authorized:
        return
      case .restricted:
        throw SpeechPermissionIssue.speechRestricted
      default:
        throw SpeechPermissionIssue.speechDenied(status)
      }

    @unknown default:
      throw SpeechPermissionIssue.speechDenied(.notDetermined)
    }
  }
}
