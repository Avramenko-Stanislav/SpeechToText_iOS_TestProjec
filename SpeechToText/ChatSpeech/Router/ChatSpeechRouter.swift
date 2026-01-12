//
//  ChatSpeechRouter.swift
//  SpeechToText
//
//  Created by Stanislav on 12.01.2026.
//

import SwiftUI
import Foundation
import SpeechRecognition
import SpeechTranscriber
import ChatDataStorage

@MainActor
protocol ChatSpeechRouter: AnyObject {
  func dismiss()
}

@MainActor
final class ChatSpeechRouterImpl: ChatSpeechRouter {

  @MainActor
  final class Context {
    let chatID: String?
    let onCompletion: () -> Void
    let speechTranscriberService: SpeechTranscriberService
    let speechPermissionsService: SpeechPermissionsService
    let chatStorageService: ChatDataStorageService

    init(
      chatID: String?,
      onCompletion: @escaping () -> Void,
      speechTranscriberService: SpeechTranscriberService,
      speechPermissionsService: SpeechPermissionsService,
      chatStorageService: ChatDataStorageService
    ) {
      self.chatID = chatID
      self.onCompletion = onCompletion
      self.speechTranscriberService = speechTranscriberService
      self.speechPermissionsService = speechPermissionsService
      self.chatStorageService = chatStorageService
    }
  }

  private init(context: Context) {
    self.context = context
  }
  private let context: Context

  static func start(context: Context) -> (ChatSpeechRouter, UIViewController) {
    let router = ChatSpeechRouterImpl(context: context)
    let viewModel = ChatSpeechViewModelImpl(
      chatID: context.chatID,
      router: router,
      speechTranscriberService: context.speechTranscriberService,
      speechPermissionsService: context.speechPermissionsService,
      chatStorageService: context.chatStorageService
    )
    let view = ChatSpeechView(viewModel: viewModel)
    let viewController = UIHostingController(rootView: view)
    return (router, viewController)
  }

  func dismiss() {
    context.onCompletion()
  }
}
