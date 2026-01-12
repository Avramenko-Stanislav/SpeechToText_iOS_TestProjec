//
//  SpeechToTextApp.swift
//  SpeechToText
//
//  Created by Stanislav on 12.01.2026.
//

import SwiftUI

@main
struct SpeechToTextApp: App {
  private let container = SpeechToTextAppContainer()

  init() {}

  var body: some Scene {
    WindowGroup {
      SpeechToTextUIKitRoot(container: container)
    }
  }
}
