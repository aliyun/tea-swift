// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Tea",
    platforms: [.macOS(.v10_15),
                .iOS(.v13),
                .tvOS(.v13),
                .watchOS(.v6)],
    products: [
        .library(
            name: "Tea",
            targets: ["Tea"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.2"),
    ],
    targets: [
        .target(
            name: "Tea",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire")
            ]),
        .testTarget(
            name: "TeaTests",
            dependencies: [
                "Tea",
                .product(name: "Alamofire", package: "Alamofire")
            ]),
    ],
    swiftLanguageVersions: [.v5]
)
