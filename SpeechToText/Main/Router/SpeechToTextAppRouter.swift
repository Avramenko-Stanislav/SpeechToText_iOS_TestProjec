//
//  SpeechToTextAppRouter.swift
//  SpeechToText
//
//  Created by Stanislav on 12.01.2026.
//

import SwiftUI
import SpeechRecognition
import SpeechTranscriber
import ChatDataStorage

@MainActor
protocol SpeechToTextAppRouter: AnyObject {
    func openNewChat()
    func openChat(chatID: String)
}

@MainActor
final class SpeechToTextAppRouterImpl: SpeechToTextAppRouter {

  struct Context {
    let navigationController: UINavigationController
    let chatStorageService: ChatDataStorageService
    let speechTranscriberService: SpeechTranscriberService
    let speechPermissionsService: SpeechPermissionsService
  }

  private let navigationController: UINavigationController
  private let chatStorageService: ChatDataStorageService
  private let speechTranscriberService: SpeechTranscriberService
  private let speechPermissionsService: SpeechPermissionsService

  private init(context: Context) {
    self.navigationController = context.navigationController
    self.chatStorageService = context.chatStorageService
    self.speechTranscriberService = context.speechTranscriberService
    self.speechPermissionsService = context.speechPermissionsService
  }

  static func start(context: Context) -> (SpeechToTextAppRouter, UIViewController) {
    let navigationController = context.navigationController
    navigationController.navigationBar.prefersLargeTitles = true

    let router = SpeechToTextAppRouterImpl(context: context)
    let view = EmptyView()
    let rootVC = UIHostingController(rootView: view)
    rootVC.view.backgroundColor = .systemBackground
    rootVC.navigationItem.largeTitleDisplayMode = .automatic

    navigationController.setViewControllers([rootVC], animated: false)

    return (router, navigationController)
  }

  func openNewChat() {
    // TODO: - will be implement at next PR.
  }

  func openChat(chatID: String) {
    // TODO: - will be implement at next PR.
  }

}
