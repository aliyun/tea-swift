// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
        name: "Tea",
        products: [
            .library(
                    name: "Tea",
                    targets: ["Tea"])
        ],
        dependencies: [
            .package(url: "https://github.com/aliyun/AlamofirePromiseKit.git", from: "1.0.0"),
            .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
            .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.3.0")
        ],
        targets: [
            .target(
                    name: "Tea",
                    dependencies: ["AlamofirePromiseKit", "CryptoSwift", "SwiftyJSON"]),
            .testTarget(
                    name: "TeaTests",
                    dependencies: ["Tea", "AlamofirePromiseKit", "CryptoSwift", "SwiftyJSON"])
        ],
        swiftLanguageVersions: [.v5]
)
