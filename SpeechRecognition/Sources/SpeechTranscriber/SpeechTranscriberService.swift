//
//  LiveSpeechService.swift
//  SpeechRecognition
//
//  Created by Stanislav on 12.01.2026.
//

import Foundation
import SpeechServiceKit
import AVFAudio
import Speech

public protocol SpeechTranscriberService: Actor {
  func start() async throws -> AsyncThrowingStream<String, Error>
  func stop()
}

public actor SpeechTranscriberManager: SpeechTranscriberService {
  private var audioEngine: any AudioEngineProvider
  private var request: (any SpeechAudioBufferRequestProvider)?
  private var task: (any SpeechRecognitionTaskProvider)?
  private let recognizer: (any SpeechRecognizerProvider)?
  private let audioSession: any AudioSessionProvider

  private var hasTap = false
  private var continuation: AsyncThrowingStream<String, Error>.Continuation?

  public init(
    audioEngine: any AudioEngineProvider = AVAudioEngine(),
    audioSession: any AudioSessionProvider = AVAudioSession.sharedInstance(),
    recognizer: (any SpeechRecognizerProvider)? = SFSpeechRecognizer(locale: .current)
  ) {
    self.audioEngine = audioEngine
    self.audioSession = audioSession
    self.recognizer = recognizer
  }

  public func start() throws -> AsyncThrowingStream<String, Error> {
    guard let recognizer else {
      throw SpeechAvailabilityError.recognizerUnavailable
    }

    guard recognizer.isAvailable else {
      throw SpeechAvailabilityError.recognizerUnavailable
    }

    stopInternal()

    let (stream, continuation) = AsyncThrowingStream<String, Error>.makeStream()
    self.continuation = continuation
    continuation.onTermination = { [weak self] _ in
      Task { await self?.stop() }
    }

    do {
      let session = audioSession
      try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
      try session.setActive(true, options: .notifyOthersOnDeactivation)

      let request = SFSpeechAudioBufferRecognitionRequest()
      request.shouldReportPartialResults = true

      if #available(iOS 13.0, *) { request.requiresOnDeviceRecognition = true }

      self.request = request

      let inputNode = audioEngine.inputNode
      let format = inputNode.outputFormat(forBus: 0)

      if hasTap {
        inputNode.removeTap(onBus: 0)
        hasTap = false
      }

      inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
        request?.append(buffer)
      }
      hasTap = true
      audioEngine.prepare()

      try audioEngine.start()

      let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
        let nsError = error as NSError?
        let text = result?.bestTranscription.formattedString
        let isFinal = result?.isFinal ?? false
        let errorDescription = error.map { ($0 as NSError).localizedDescription }

        Task { @MainActor [weak self] in
          await self?.handleSnapshot(text: text, isFinal: isFinal, errorDescription: errorDescription)
        }
      }

      self.task = task

      return stream
    } catch {
      stopInternal()
      throw error
    }
  }

  public func stop() {
    stopInternal()
    try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func handleSnapshot(text: String?, isFinal: Bool, errorDescription: String?) {
    if let text {
      continuation?.yield(text)
      if isFinal {
        stopInternal()
      }
      return
    }

    if let errorDescription {
      continuation?.finish(throwing: SpeechTranscriberManagerError.recognitionFailed(errorDescription))
      stopInternal()
    }
  }

  private func stopInternal() {
    task?.cancel()
    task = nil

    request?.endAudio()
    request = nil

    if audioEngine.isRunning {
      audioEngine.stop()
    }

    if hasTap {
      audioEngine.inputNode.removeTap(onBus: 0)
      hasTap = false
    }

    continuation?.finish()
    continuation = nil
  }
}
