// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpeechRecognition",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "SpeechRecognition",
            targets: ["SpeechRecognition", "SpeechTranscriber", "SpeechServiceKit"])
    ],
    targets: [
        .target(
            name: "SpeechRecognition", dependencies: ["SpeechServiceKit"]),
        .target(name: "SpeechTranscriber", dependencies: ["SpeechServiceKit"]),
        .target(name: "SpeechServiceKit"),
        .testTarget(
            name: "SpeechRecognitionTests",
            dependencies: ["SpeechRecognition", "SpeechServiceKit"]
        ),
    ]
)
