// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "App",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "Chat",
            targets: ["Chat"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.0.0"),
        .package(url: "https://github.com/rchatham/LangTools.swift.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "Chat",
            dependencies: [
                .product(name: "LangTools", package: "langtools.swift"),
                .product(name: "OpenAI", package: "langtools.swift"),
                .product(name: "Anthropic", package: "langtools.swift"),
                .product(name: "XAI", package: "langtools.swift"),
                "KeychainAccess"
            ],
            path: "Modules/Chat"),
    ]
)

