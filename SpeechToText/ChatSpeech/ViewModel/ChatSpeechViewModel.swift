//
//  ChatSpeechViewModel.swift
//  SpeechToText
//
//  Created by Stanislav on 12.01.2026.
//

import SwiftUI
import SpeechTranscriber
import ChatDataStorage
import SpeechRecognition
import SpeechServiceKit

@MainActor
protocol ChatSpeechViewModel: ObservableObject, AnyObject {
  var messages: [String] { get }
  var liveText: String { get }
  var viewState: ChatSpeechViewState { get }

  var screen: ChatSpeechScreen { get }
  var canShowSave: Bool { get }
  var recordButtonTitle: String { get }
  var isRecordButtonDisabled: Bool { get }
  var errorText: String? { get }

  var pendingURL: URL? { get }
  func clearPendingURL()

  func onAppear()
  func onDisappear()

  func saveTapped() async
  func recordTapped() async
}

enum ChatSpeechScreen: Equatable {
  case progress(title: String?)
  case permissionGate(model: PermissionGateView.Model)
  case content
}

@MainActor
enum ChatSpeechViewState: Equatable {
  case checkingAccess
  case needsAccess
  case requestingAccess
  case denied(message: String, canOpenSettings: Bool)
  case restricted(message: String)

  case ready
  case recording

  case error(message: String)
}

import UIKit

@MainActor
final class ChatSpeechViewModelImpl: ChatSpeechViewModel {

  @Published private(set) var viewState: ChatSpeechViewState = .checkingAccess
  @Published var messages: [String] = []
  @Published var liveText: String = ""

  @Published private(set) var pendingURL: URL?

  // MARK: Private

  private var streamTask: Task<Void, Never>?
  private var startTask: Task<Void, Never>?
  private var isSaving = false

  private let speechTranscriberService: SpeechTranscriberService
  private let speechPermissionsService: SpeechPermissionsService
  private let chatStorageService: ChatDataStorageService
  private let router: ChatSpeechRouter
  private let chatID: String?

  init(
    chatID: String?,
    router: ChatSpeechRouter,
    speechTranscriberService: SpeechTranscriberService,
    speechPermissionsService: SpeechPermissionsService,
    chatStorageService: ChatDataStorageService
  ) {
    self.chatID = chatID
    self.router = router
    self.speechTranscriberService = speechTranscriberService
    self.speechPermissionsService = speechPermissionsService
    self.chatStorageService = chatStorageService
  }

  // MARK: Presentation

  private func viewState(for access: SpeechAccess) -> ChatSpeechViewState {
    switch access {
    case .ready:
      return .ready
    case .needsRequest:
      return .needsAccess
    case .denied(let message, let canOpenSettings):
      return .denied(message: message, canOpenSettings: canOpenSettings)
    case .restricted(let message):
      return .restricted(message: message)
    }
  }

  private func apply(access: SpeechAccess) {
    viewState = viewState(for: access)
  }

  var screen: ChatSpeechScreen {
    switch viewState {
    case .checkingAccess:
      return .progress(title: nil)

    case .requestingAccess:
      return .progress(title: Constants.requestingAccessTitle)

    case .needsAccess:
      return .permissionGate(model: makeNeedsAccessModel())

    case .denied(let message, let canOpenSettings):
      return .permissionGate(model: makeDeniedModel(message: message, canOpenSettings: canOpenSettings))

    case .restricted(let message):
      return .permissionGate(model: makeRestrictedModel(message: message))

    case .ready, .recording, .error:
      return .content
    }
  }

  var canShowSave: Bool {
    guard viewState != .recording, viewState != .requestingAccess, !isSaving else { return false }
    return !normalizedMessages().isEmpty
  }

  var recordButtonTitle: String {
    viewState == .recording ? Constants.stopTitle : Constants.recordTitle
  }

  var isRecordButtonDisabled: Bool {
    viewState == .requestingAccess || isSaving
  }

  var errorText: String? {
    if case .error(let msg) = viewState { return msg }
    return nil
  }

  func clearPendingURL() {
    pendingURL = nil
  }

  // MARK: View lifecycle

  func onAppear() {
    refreshAccess()
    Task { await loadExistingChatIfNeeded() }
  }

  @discardableResult
  private func ensureReadyAccess() -> Bool {
    let access = speechPermissionsService.currentAccess()
    if case .ready = access { return true }

    apply(access: access)
    return false
  }

  private var didLoadChat = false

  private func loadExistingChatIfNeeded() async {
    guard !didLoadChat else { return }
    didLoadChat = true

    guard let raw = chatID?.trimmingCharacters(in: Constants.trimSet), !raw.isEmpty else { return }

    do {
      let row = try await chatStorageService.fetchChat(chatID: raw)
      let transcript = (row.lastMessagePreview ?? "").trimmingCharacters(in: Constants.trimSet)
      guard !transcript.isEmpty else { return }

      let parts = transcript
        .split(separator: Constants.newlineChar, omittingEmptySubsequences: true)
        .map { String($0).trimmingCharacters(in: Constants.trimSet) }
        .filter { !$0.isEmpty }

      if !parts.isEmpty {
        messages = parts
      }
    } catch {
      viewState = .error(message: error.localizedDescription)
    }
  }

  func onDisappear() {
    stopRecording()
  }

  // MARK: Actions

  func saveTapped() async {
    await saveTranscriptAsChat()
  }

  func recordTapped() async {
    if viewState == .recording {
      stopRecording()
    } else {
      await startRecording()
    }
  }

  // MARK: Gate models

  private func makeNeedsAccessModel() -> PermissionGateView.Model {
    .init(
      title: Constants.needsAccessTitle,
      message: Constants.needsAccessMessage,
      primaryTitle: Constants.allowTitle,
      primaryAction: { [weak self] in
        guard let self else { return }
        Task { await self.requestAccess() }
      },
      secondaryTitle: Constants.refreshTitle,
      secondaryAction: { [weak self] in
        self?.refreshAccess()
      }
    )
  }

  private func makeDeniedModel(message: String, canOpenSettings: Bool) -> PermissionGateView.Model {
    .init(
      title: Constants.deniedTitle,
      message: message,
      primaryTitle: canOpenSettings ? Constants.openSettingsTitle : Constants.okTitle,
      primaryAction: { [weak self] in
        guard let self else { return }
        guard canOpenSettings else { return }
        self.pendingURL = URL(string: UIApplication.openSettingsURLString)
      },
      secondaryTitle: Constants.refreshTitle,
      secondaryAction: { [weak self] in
        self?.refreshAccess()
      }
    )
  }

  private func makeRestrictedModel(message: String) -> PermissionGateView.Model {
    .init(
      title: Constants.restrictedTitle,
      message: message,
      primaryTitle: Constants.refreshTitle,
      primaryAction: { [weak self] in
        self?.refreshAccess()
      },
      secondaryTitle: nil,
      secondaryAction: nil
    )
  }

  // MARK: Access

  func refreshAccess() {
    apply(access: speechPermissionsService.currentAccess())
  }

  func requestAccess() async {
    guard viewState != .requestingAccess else { return }

    viewState = .requestingAccess

    let access = await speechPermissionsService.requestIfNeeded()
    apply(access: access)
  }

  // MARK: Recording

  func startRecording() async {
    guard ensureReadyAccess() else { return }

    guard viewState != .recording else { return }
    guard startTask == nil else { return }

    startTask = Task { @MainActor [weak self] in
      guard let self else { return }
      defer { self.startTask = nil }

      do {
        let stream = try await speechTranscriberService.start()
        self.viewState = .recording

        self.streamTask?.cancel()
        self.streamTask = Task { @MainActor [weak self] in
          guard let self else { return }
          do {
            for try await text in stream {
              self.liveText = text
            }
          } catch is CancellationError {

          } catch {
            self.viewState = .error(message: error.localizedDescription)
          }
        }
      } catch {
        self.viewState = .error(message: error.localizedDescription)
      }
    }
  }

  func stopRecording() {
    startTask?.cancel()
    startTask = nil

    guard viewState == .recording else { return }

    streamTask?.cancel()
    streamTask = nil

    let final = liveText.trimmingCharacters(in: Constants.trimSet)
    liveText = ""

    Task { await speechTranscriberService.stop() }

    if !final.isEmpty {
      messages.append(final)
      viewState = .ready
    } else {
      viewState = normalizedMessages().isEmpty ? .error(message: Constants.emptyRecordingError) : .ready
    }
  }

  // MARK: Saving

  private func normalizedMessages() -> [String] {
    messages
      .map { $0.trimmingCharacters(in: Constants.trimSet) }
      .filter { !$0.isEmpty }
  }

  private func saveTranscriptAsChat() async {
    guard !isSaving else { return }
    isSaving = true
    defer { isSaving = false }

    if viewState == .recording {
      stopRecording()
    }

    let cleaned = normalizedMessages()
    guard !cleaned.isEmpty else {
      viewState = .error(message: Constants.emptyRecordingError)
      return
    }

    do {
      let transcript = cleaned.joined(separator: Constants.newlineString)

      _ = try await chatStorageService.upsertChat(chatID: chatID, title: nil, transcript: transcript)

      viewState = .ready
      router.dismiss()
    } catch {
      viewState = .error(message: error.localizedDescription)
    }
  }

  deinit {
    streamTask?.cancel()
    startTask?.cancel()
  }
}

private enum Constants {
  static let requestingAccessTitle = "Requesting access…"

  static let needsAccessTitle = "Access required"
  static let needsAccessMessage =
  "To record and transcribe speech, we need permission for the microphone and speech recognition."
  static let allowTitle = "Allow"
  static let refreshTitle = "Refresh"

  static let deniedTitle = "Access denied"
  static let openSettingsTitle = "Open Settings"
  static let okTitle = "OK"

  static let restrictedTitle = "Access restricted"

  static let recordTitle = "Record"
  static let stopTitle = "Stop"

  static let emptyRecordingError = "Empty recording"

  static let trimSet = CharacterSet.whitespacesAndNewlines
  static let newlineString = "\n"
  static let newlineChar: Character = "\n"
}
