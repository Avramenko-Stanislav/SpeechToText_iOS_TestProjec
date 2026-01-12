//
//  PermissionGateView.swift
//  SpeechToText
//
//  Created by Stanislav on 12.01.2026.
//

import SwiftUI

struct PermissionGateView: View {

  struct Model: Equatable {
    let title: String
    let message: String
    let primaryTitle: String
    let primaryAction: () -> Void

    static func == (lhs: Model, rhs: Model) -> Bool {
      lhs.title == rhs.title &&
      lhs.message == rhs.message &&
      lhs.primaryTitle == rhs.primaryTitle
    }
  }

  let model: Model

  var body: some View {
    VStack(spacing: Constants.spacing) {
      Spacer()

      Text(model.title)
        .font(.title2)
        .bold()

      Text(model.message)
        .font(.body)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)

      Button(action: model.primaryAction) {
        Text(model.primaryTitle)
          .frame(maxWidth: .infinity, minHeight: Constants.buttonHeight)
      }
      .buttonStyle(.borderedProminent)

      Spacer()
    }
    .padding(Constants.padding)
  }
}

private enum Constants {
  static let buttonHeight: CGFloat = 34
  static let spacing = CGFloat(12)
  static let padding = CGFloat(12)
}
