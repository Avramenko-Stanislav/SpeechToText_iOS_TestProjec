//
//  SpeechToTextUIKitRoot.swift
//  SpeechToText
//
//  Created by Stanislav on 12.01.2026.
//

import SwiftUI

struct SpeechToTextUIKitRoot: UIViewControllerRepresentable {
  let container: SpeechToTextAppContainer

  func makeUIViewController(context: Context) -> UIViewController {
    container.rootViewController
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
