//
//  AllChatsView.swift
//  SpeechToText
//
//  Created by Stanislav on 12.01.2026.
//

import SwiftUI
import Foundation
import ChatDataKit

struct AllChatsView<ViewModel: AllChatsViewModel>: View {
  @ObservedObject private var viewModel: ViewModel

  init(viewModel: ViewModel) {
    self.viewModel = viewModel
  }

  var body: some View {
    screenContent
      .navigationTitle(Constants.Strings.title)
      .safeAreaInset(edge: .bottom) {
        newChatButton
      }
      .task {
        await loadChats()
      }
  }

  // MARK: - Screen content

  @ViewBuilder
  private var screenContent: some View {
    switch viewModel.viewState {
    case .idle, .isLoading:
      loadingView

    case .onSuccess(let rows):
      onSuccenState(rows: rows)

    case .onError(let message):
      errorView(message: message)
    }
  }

  @ViewBuilder
  private func onSuccenState(rows: [ChatRow]) -> some View {
    if rows.isEmpty {
      emptyStateView
    } else {
      chatsList(rows: rows)
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: Constants.UI.emptySpacing) {
      Image(systemName: Constants.Assets.emptyIcon)
        .font(.system(size: Constants.UI.emptyIconSize))
        .foregroundStyle(.secondary)

      Text(Constants.Strings.emptyTitle)
        .font(.headline)

      Text(Constants.Strings.emptySubtitle)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(Constants.UI.emptyPadding)
    .accessibilityIdentifier(Constants.A11y.empty)
  }

  private var loadingView: some View {
    ZStack {
      Color.black.opacity(Constants.UI.loadingOverlayOpacity)

      ProgressView()
        .accessibilityIdentifier(Constants.A11y.loading)
    }
    .ignoresSafeArea()
  }

  private func chatsList(rows: [ChatRow]) -> some View {
    List {
      ForEach(rows) { row in
        chatRowButton(for: row)
      }
    }
    .accessibilityIdentifier(Constants.A11y.screen)
    .refreshable {
      await loadChats()
    }
  }

  private func chatRowButton(for row: ChatRow) -> some View {
    Button {
      Task { await viewModel.openChat(chatID: row.id) }
    } label: {
      VStack(alignment: .leading, spacing: Constants.UI.rowSpacing) {
        Text(row.title)
          .font(.headline)

        Text(messagePreviewText(for: row))
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityIdentifier(Constants.A11y.chatRowPrefix + row.id)
  }

  private func errorView(message: String) -> some View {
    VStack(spacing: Constants.UI.errorSpacing) {
      Text(Constants.Strings.loadErrorTitle)

      Text(message)
        .font(.footnote)
        .foregroundStyle(.secondary)

      Button(Constants.Strings.retry) {
        Task { await loadChats() }
      }
    }
    .padding(Constants.UI.errorPadding)
    .accessibilityIdentifier(Constants.A11y.error)
  }

  private var newChatButton: some View {
    PrimaryFullWidthButton(
      title: Constants.Strings.newChat,
      isDisabled: viewModel.viewState.isLoading,
      accessibilityID: Constants.A11y.newChatButton
    ) {
      await viewModel.openNewChat()
    }
  }

  // MARK: - Helpers

  private func loadChats() async {
    await viewModel.load()
  }

  private func messagePreviewText(for row: ChatRow) -> String {
    let preview = (row.lastMessagePreview ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    return preview.isEmpty ? Constants.Strings.noMessagesYet : preview
  }
}

// MARK: - Constants

private enum Constants {
  enum Strings {
    static let title = "All Chats"
    static let noMessagesYet = "No messages yet"
    static let loadErrorTitle = "Failed to load chats"
    static let retry = "Retry"
    static let newChat = "New chat"
    static let emptyTitle = "Nothing here yet"
    static let emptySubtitle = "Create your first chat - it will show up here."
  }

  enum Assets {
    static let emptyIcon = "bubble.left.and.bubble.right"
  }

  enum A11y {
    static let screen = "screen.all_chats"
    static let loading = "screen.all_chats.loading"
    static let error = "screen.all_chats.error"
    static let empty = "screen.all_chats.empty"
    static let newChatButton = "button.new_chat"
    static let chatRowPrefix = "chat_row."
  }

  enum UI {
    static let loadingOverlayOpacity: Double = 0.3

    static let rowSpacing: CGFloat = 6

    static let errorSpacing: CGFloat = 12
    static let errorPadding: CGFloat = 16

    static let newChatVerticalPadding: CGFloat = 14
    static let newChatHorizontalPadding: CGFloat = 16
    static let newChatBottomPadding: CGFloat = 12

    static let emptySpacing: CGFloat = 10
    static let emptyPadding: CGFloat = 24
    static let emptyIconSize: CGFloat = 44
    static let emptyButtonTopPadding: CGFloat = 6
  }
}
