//
//  ChatSpeechView.swift
//  SpeechToText
//
//  Created by Stanislav on 12.01.2026.
//

import SwiftUI

struct ChatSpeechView<ViewModel: ChatSpeechViewModel>: View {
  @ObservedObject var viewModel: ViewModel
  @Environment(\.openURL) private var openURL

  var body: some View {
    Group {
      switch viewModel.screen {
      case .progress(let title):
          ProgressView(title ?? "")

      case .permissionGate(let model):
        PermissionGateView(model: model)

      case .content:
          content
      }
    }
    .onAppear { viewModel.onAppear() }
    .onDisappear { viewModel.onDisappear() }
    .onChange(of: viewModel.pendingURL) { _, url in
      guard let url else { return }
      openURL(url)
      viewModel.clearPendingURL()
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        if viewModel.canShowSave {
          Button(Strings.saveChat) {
            Task { await viewModel.saveTapped() }
          }
        }
      }
    }
  }

  private var content: some View {
    VStack(spacing: Layout.verticalStackSpacing) {
        ScrollViewReader { proxy in
          ScrollView {
            LazyVStack(alignment: .leading, spacing: Layout.messagesSpacing) {
              ForEach(Array(viewModel.messages.enumerated()), id: \.offset) { index, msg in
                Text(msg)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(Layout.messagePadding)
                  .background(.ultraThinMaterial)
                  .clipShape(RoundedRectangle(cornerRadius: Layout.messageCornerRadius, style: .continuous))
                  .id(Identifiers.messageID(for: index))
              }

              if viewModel.viewState == .recording {
                let live = viewModel.liveText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !live.isEmpty {
                  VStack(alignment: .leading, spacing: Layout.liveBlockSpacing) {
                    Text(Strings.liveDictationTitle)
                      .font(.footnote)
                      .foregroundStyle(.secondary)

                    Text(live)
                      .frame(maxWidth: .infinity, alignment: .leading)
                  }
                  .padding(Layout.messagePadding)
                  .background(.thinMaterial)
                  .clipShape(RoundedRectangle(cornerRadius: Layout.messageCornerRadius, style: .continuous))
                  .overlay(
                    RoundedRectangle(cornerRadius: Layout.messageCornerRadius, style: .continuous)
                      .strokeBorder(
                        .secondary.opacity(Layout.liveBorderOpacity),
                        lineWidth: Layout.liveBorderLineWidth
                      )
                  )
                  .id(Identifiers.liveID)
                }
              }

              Color.clear
                .frame(height: Layout.bottomSpacerHeight)
                .id(Identifiers.bottomID)
            }
            .padding(.horizontal)
            .padding(.top, Layout.scrollTopPadding)
            .padding(.bottom, Layout.scrollBottomPadding)
          }
          .overlay { emptyStateOverlay }
          .onChange(of: viewModel.messages.count) { _, _ in
            withAnimation { proxy.scrollTo(Identifiers.bottomID, anchor: .bottom) }
          }
          .onChange(of: viewModel.liveText) { _, _ in
            guard viewModel.viewState == .recording else { return }
            proxy.scrollTo(Identifiers.bottomID, anchor: .bottom)
          }
        }

        if let msg = viewModel.errorText {
          Text(msg)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
      viewModel.onAppear()
    }
    .safeAreaInset(edge: .bottom) {
      recordButton
    }
  }

    private var recordButton: some View {
      PrimaryFullWidthButton(
        title: viewModel.recordButtonTitle,
        isDisabled: viewModel.isRecordButtonDisabled
      ) {
        await viewModel.recordTapped()
      }
    }

  private var shouldShowEmptyState: Bool {
    viewModel.messages.isEmpty && viewModel.viewState != .recording
  }

  @ViewBuilder
  private var emptyStateOverlay: some View {
    if shouldShowEmptyState {
      if #available(iOS 17.0, *) {
        ContentUnavailableView {
          Label(Strings.emptyTitle, systemImage: Strings.emptyIcon)
        } description: {
          Text(Strings.emptyMessage)
        }
        .padding(.horizontal, Layout.emptyHorizontalPadding)
        .padding(.bottom, Layout.emptyBottomPadding)
      } else {
        VStack(spacing: Layout.emptySpacing) {
          Image(systemName: Strings.emptyIcon)
            .font(.system(size: Layout.emptyIconSize))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.secondary)

          Text(Strings.emptyTitle)
            .font(.title3.weight(.semibold))

          Text(Strings.emptyMessage)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Layout.emptyHorizontalPadding)
        .padding(.bottom, Layout.emptyBottomPadding)
      }
    }
  }
}

// MARK: - Constants

private enum Strings {
  static let saveChat = "Save chat"
  static let liveDictationTitle = "Dictating now"

  static let emptyIcon = "mic.circle"
  static let emptyTitle = "No recordings yet"
  static let emptyMessage = "Tap “Record” below to start dictating. Your transcriptions will appear here."
}

private enum Layout {
  static let verticalStackSpacing: CGFloat = 12
  static let messagesSpacing: CGFloat = 12

  static let messagePadding: CGFloat = 12
  static let messageCornerRadius: CGFloat = 14

  static let liveBlockSpacing: CGFloat = 6
  static let liveBorderOpacity: Double = 0.25
  static let liveBorderLineWidth: CGFloat = 1

  static let bottomSpacerHeight: CGFloat = 1

  static let scrollTopPadding: CGFloat = 12
  static let scrollBottomPadding: CGFloat = 24

  static let recordButtonVerticalPadding: CGFloat = 14
  static let recordButtonBottomPadding: CGFloat = 12

  // Empty state
  static let emptySpacing: CGFloat = 10
  static let emptyIconSize: CGFloat = 44
  static let emptyHorizontalPadding: CGFloat = 24
  static let emptyBottomPadding: CGFloat = 40
}

private enum Identifiers {
  static let messagePrefix = "msg."
  static let liveID = "live"
  static let bottomID = "bottom"

  static func messageID(for index: Int) -> String {
    "\(messagePrefix)\(index)"
  }
}
