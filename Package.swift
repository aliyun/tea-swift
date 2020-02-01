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
            .package(url: "https://github.com/aliyun/AlamofirePromiseKit.git", from: "1.0.0")
        ],
        targets: [
            .target(
                    name: "Tea",
                    dependencies: [
                        "AlamofirePromiseKit"
                    ]),
            .testTarget(
                    name: "TeaTests",
                    dependencies: ["Tea", "AlamofirePromiseKit"])
        ],
        swiftLanguageVersions: [.v5]
)
