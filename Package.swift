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
            .package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.9.1"),
            .package(url: "https://github.com/yannickl/AwaitKit.git", from: "5.2.0")
        ],
        targets: [
            .target(
                    name: "Tea",
                    dependencies: [
                        "Alamofire",
                        "AwaitKit"
                    ]),
            .testTarget(
                    name: "TeaTests",
                    dependencies: ["Tea", "Alamofire", "AwaitKit"])
        ],
        swiftLanguageVersions: [.v5]
)
