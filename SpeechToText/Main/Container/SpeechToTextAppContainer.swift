//
//  SpeechToTextAppContainer.swift
//  SpeechToText
//
//  Created by Stanislav on 12.01.2026.
//

import UIKit
import ChatDataStorage
import SpeechTranscriber
import SpeechRecognition

@MainActor
final class SpeechToTextAppContainer {

  private let router: SpeechToTextAppRouter
  let rootViewController: UIViewController

  init(
    repository: ChatDataStorageService = ChatDataStorageManager(),
    transcriber: SpeechTranscriberService = SpeechTranscriberManager(),
    speechService: SpeechPermissionsService = SpeechPermissionsManager(),
    navigationController: UINavigationController = UINavigationController()
  ) {
    let (router, navigationController) = SpeechToTextAppRouterImpl.start(context: .init(
      navigationController: navigationController,
      chatStorageService: repository,
      speechTranscriberService: transcriber,
      speechPermissionsService: speechService
    ))
    self.router = router
    self.rootViewController = navigationController
  }
}
