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
    let secondaryTitle: String?
    let secondaryAction: (() -> Void)?

    static func == (lhs: Model, rhs: Model) -> Bool {
      lhs.title == rhs.title &&
      lhs.message == rhs.message &&
      lhs.primaryTitle == rhs.primaryTitle &&
      lhs.secondaryTitle == rhs.secondaryTitle
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

      if let secondaryTitle = model.secondaryTitle,
         let secondaryAction = model.secondaryAction {
        Button(action: secondaryAction) {
          Text(secondaryTitle)
            .frame(maxWidth: .infinity, minHeight: Constants.buttonHeight)
        }
        .buttonStyle(.bordered)
      }

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
