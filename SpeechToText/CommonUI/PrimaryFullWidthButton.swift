//
//  PrimaryFullWidthButton.swift
//  SpeechToText
//
//  Created by Stanislav on 12.01.2026.
//


import SwiftUI

struct PrimaryFullWidthButton: View {
  let title: String
  let isDisabled: Bool
  let accessibilityID: String?
  let action: () async -> Void

  init(
    title: String,
    isDisabled: Bool,
    accessibilityID: String? = nil,
    action: @escaping () async -> Void
  ) {
    self.title = title
    self.isDisabled = isDisabled
    self.accessibilityID = accessibilityID
    self.action = action
  }

  var body: some View {
    Button {
      Task { await action() }
    } label: {
      Text(title)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Constants.verticalPadding)
        .contentShape(Rectangle())
    }
    .buttonStyle(.borderedProminent)
    .disabled(isDisabled)
    .padding(.horizontal, Constants.horizontalPadding)
    .padding(.bottom, Constants.bottomPadding)
    .applyAccessibilityID(accessibilityID)
  }
}

private extension View {
  @ViewBuilder
  func applyAccessibilityID(_ id: String?) -> some View {
    if let id {
      self.accessibilityIdentifier(id)
    } else {
      self
    }
  }
}

// MARK: - Constants

private enum Constants {
  static let verticalPadding: CGFloat = 14
  static let horizontalPadding: CGFloat = 16
  static let bottomPadding: CGFloat = 12
}
