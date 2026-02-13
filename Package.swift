// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MDown",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.0")
    ],
    targets: [
        .executableTarget(
            name: "MDown",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui")
            ],
            path: "Sources/MDown"
        )
    ]
)
