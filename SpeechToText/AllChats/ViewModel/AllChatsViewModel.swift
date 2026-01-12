//
//  AllChatsViewModel.swift
//  SpeechToText
//
//  Created by Stanislav on 12.01.2026.
//

import Foundation
import ChatDataStorage

@MainActor
protocol AllChatsViewModel: ObservableObject {
  var viewState: AllChatsViewState { get }

  func load() async
  func openNewChat() async
  func openChat(chatID: String) async
}

@MainActor
final class AllChatsViewModelImpl: AllChatsViewModel {
  private let chatStorageService: ChatDataStorageService
  private let router: SpeechToTextAppRouter

  @Published private(set) var viewState: AllChatsViewState = .idle

  init(router: SpeechToTextAppRouter, chatStorageService: ChatDataStorageService) {
    self.router = router
    self.chatStorageService = chatStorageService
  }

  func load() async {
    guard viewState != .isLoading else { return }
    viewState = .isLoading

    do {
      let rows = try await chatStorageService.fetchAllChats()
      viewState = .onSuccess(rows: rows)
    } catch {
      viewState = .onError(message: error.localizedDescription)
    }
  }

  func openNewChat() async {
    router.openNewChat()
  }

  func openChat(chatID: String) async {
    router.openChat(chatID: chatID)
  }
}
