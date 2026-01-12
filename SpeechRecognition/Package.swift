// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpeechRecognition",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "SpeechRecognition",
            targets: ["SpeechRecognition", "SpeechTranscriber"])
    ],
    targets: [
        .target(
            name: "SpeechRecognition"),
        .target(name: "SpeechTranscriber"),
        .testTarget(
            name: "SpeechRecognitionTests",
            dependencies: ["SpeechRecognition"]
        ),
    ]
)
