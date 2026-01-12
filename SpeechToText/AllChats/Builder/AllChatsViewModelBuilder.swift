//
//  AllChatsViewModelBuilder.swift
//  SpeechToText
//
//  Created by Stanislav on 12.01.2026.
//

import Foundation
import ChatDataStorage

@MainActor
protocol AllChatsViewModelBuilder: AnyObject {
  func build(
    router: SpeechToTextAppRouter,
    chatStorageService: ChatDataStorageService
  ) -> AllChatsViewModelImpl
}

@MainActor
final class AllChatsViewModelBuilderImpl: AllChatsViewModelBuilder {
  func build(
    router: SpeechToTextAppRouter,
    chatStorageService: ChatDataStorageService
  ) -> AllChatsViewModelImpl {
    AllChatsViewModelImpl(
      router: router,
      chatStorageService: chatStorageService
    )
  }
}
