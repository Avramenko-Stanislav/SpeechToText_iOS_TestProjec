import Testing
import SpeechServiceKit
import AVFoundation
import Speech
@testable import SpeechRecognition

@Suite(.serialized)
@MainActor
struct SpeechPermissionsManagerTests {

  let audioApplicationProviderSpy = AudioApplicationProviderSpy()
  let audioSessionSpy = AudioSessionProviderSpy()
  let speechRecognizerSpy = SpeechRecognizerProviderSpy()
  let permissionGateServiceSpy = PermissionGateServiceSpy()

  func makeSUT() async -> SpeechPermissionsManager {
    await resetSpyStates()

    return SpeechPermissionsManager(
      permissionGate: permissionGateServiceSpy,
      audioApplication: audioApplicationProviderSpy,
      audioSession: audioSessionSpy,
      speechRecognizer: SpeechRecognizerProviderSpy.self
    )
  }

  func resetSpyStates() async {
    audioApplicationProviderSpy.reset()
    audioSessionSpy.reset()
    SpeechRecognizerProviderSpy.reset()
    await permissionGateServiceSpy.reset()
  }

  @Test
  func test_currentAccess_get_whenSpeechRestricted_thenRestricted() async {
    // Get
    let sut = await makeSUT()

    // When
    audioApplicationProviderSpy.recordPermissionStub = .denied
    SpeechRecognizerProviderSpy.authorizationStatusStub = .restricted

    // Then
    let result = sut.currentAccess()

    #expect(result == .restricted(message: SpeechPermissionIssue.speechRestricted.localizedDescription))
    #expect(audioApplicationProviderSpy.recordedActions == [.recordPermissionCall])
    #expect(SpeechRecognizerProviderSpy.recordedActions == [.authorizationStatus])
  }

  @Test
  func test_currentAccess_get_whenMicDenied_thenDeniedMic() async {
    // Get
    let sut = await makeSUT()

    // When
    audioApplicationProviderSpy.recordPermissionStub = .denied
    SpeechRecognizerProviderSpy.authorizationStatusStub = .authorized

    // Then
    let result = sut.currentAccess()

    #expect(result == .denied(
      message: SpeechPermissionIssue.microphoneDenied.localizedDescription,
      canOpenSettings: true)
    )
    #expect(audioApplicationProviderSpy.recordedActions == [.recordPermissionCall])
    #expect(SpeechRecognizerProviderSpy.recordedActions == [.authorizationStatus])
  }

  @Test
  func test_currentAccess_get_whenSpeechDenied_thenDeniedSpeech() async {
    // Get
    let sut = await makeSUT()

    // When
    audioApplicationProviderSpy.recordPermissionStub = .granted
    SpeechRecognizerProviderSpy.authorizationStatusStub = .denied

    // Then
    let result = sut.currentAccess()

    #expect(result == .denied(
      message: SpeechPermissionIssue.speechDenied(.denied).localizedDescription,
      canOpenSettings: true)
    )
    #expect(audioApplicationProviderSpy.recordedActions == [.recordPermissionCall])
    #expect(SpeechRecognizerProviderSpy.recordedActions == [.authorizationStatus])
  }

  @Test
  func test_currentAccess_get_whenNeedsRequest_thenNeedsRequest() async {
    // Get
    let sut = await makeSUT()

    // When
    audioApplicationProviderSpy.recordPermissionStub = .undetermined
    SpeechRecognizerProviderSpy.authorizationStatusStub = .authorized

    // Then
    let result = sut.currentAccess()

    #expect(result == .needsRequest)
    #expect(audioApplicationProviderSpy.recordedActions == [.recordPermissionCall])
    #expect(SpeechRecognizerProviderSpy.recordedActions == [.authorizationStatus])
  }

  @Test
  func test_currentAccess_get_whenMicGrantedAndSpeechAuthorized_thenReady() async {
    // Get
    let sut = await makeSUT()

    // When
    audioApplicationProviderSpy.recordPermissionStub = .granted
    SpeechRecognizerProviderSpy.authorizationStatusStub = .authorized

    // Then
    let result = sut.currentAccess()

    #expect(result == .ready)
    #expect(audioApplicationProviderSpy.recordedActions == [.recordPermissionCall])
    #expect(SpeechRecognizerProviderSpy.recordedActions == [.authorizationStatus])
  }

  @Test
  func requestIfNeeded_whenAlreadyReady_doesNotPrompt_returnsReady() async {
    // Get
    let sut = await makeSUT()

    // When
    audioApplicationProviderSpy.recordPermissionStub = .granted
    SpeechRecognizerProviderSpy.authorizationStatusStub = .authorized

    // Then
    let result = await sut.requestIfNeeded()

    #expect(result == .ready)
    #expect(audioApplicationProviderSpy.recordedActions == [.recordPermissionCall])
    #expect(SpeechRecognizerProviderSpy.recordedActions == [.authorizationStatus])
    #expect(await permissionGateServiceSpy.recordedActions() == [])
  }

  @Test
  func requestIfNeeded_whenNeedsRequest_butSessionDenied_returnsDenied_withoutPrompts() async {
    // Get
    let sut = await makeSUT()

    // When
    audioApplicationProviderSpy.recordPermissionStub = .undetermined
    SpeechRecognizerProviderSpy.authorizationStatusStub = .notDetermined
    audioSessionSpy.recordPermissionStub = .denied

    // Then
    let result = await sut.requestIfNeeded()

    #expect(result == .denied(
      message: SpeechPermissionIssue.microphoneDenied.localizedDescription,
      canOpenSettings: true
    ))
    #expect(audioApplicationProviderSpy.recordedActions == [.recordPermissionCall])
    #expect(SpeechRecognizerProviderSpy.recordedActions == [.authorizationStatus])

    #expect(audioSessionSpy.recordedActions.contains(.recordPermission))
    #expect(audioSessionSpy.recordedActions.contains(.requestRecordPermission) == false)

    let gateActions = await permissionGateServiceSpy.recordedActions()
    #expect(gateActions.contains(.joinOrBecomeOwner))
  }

  @Test
  func requestIfNeeded_whenNeedsRequest_promptsMicAndSpeech_andReturnsReady() async {
    // Get
    let sut = await makeSUT()

    // When
    audioApplicationProviderSpy.recordPermissionStub = .undetermined
    audioSessionSpy.recordPermissionStub = .undetermined
    SpeechRecognizerProviderSpy.authorizationStatusStub = .notDetermined

    audioSessionSpy.requestRecordPermissionStub = { response in
      audioSessionSpy.recordPermissionStub = .granted
      audioApplicationProviderSpy.recordPermissionStub = .granted
      response(true)
    }

    SpeechRecognizerProviderSpy.requestAuthorizationStub = .authorized
    SpeechRecognizerProviderSpy.onRequestAuthorization = {
      SpeechRecognizerProviderSpy.authorizationStatusStub = .authorized
    }

    // Then
    let result = await sut.requestIfNeeded()
    #expect(result == .ready)

    #expect(audioSessionSpy.recordedActions.contains(.requestRecordPermission))
    #expect(SpeechRecognizerProviderSpy.recordedActions.contains(.requestAuthorization))

    #expect(await permissionGateServiceSpy.recordedActions() == [.joinOrBecomeOwner, .completeSuccess])
  }
}
