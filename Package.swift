// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Linux) && compiler(<5.8)
#error("Tea on Linux requires Swift 5.8 or later.")
#endif

#if os(Linux)
var transportDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.21.0")
]
#if compiler(<5.9)
// Newer NIO manifests use APIs unavailable in Swift 5.8.
transportDependencies.append(.package(url: "https://github.com/apple/swift-nio-transport-services.git", "1.19.0"..<"1.24.0"))
transportDependencies.append(.package(url: "https://github.com/apple/swift-nio-extras.git", "1.13.0"..<"1.25.0"))
#endif
let transportProduct: Target.Dependency = .product(name: "AsyncHTTPClient", package: "async-http-client")
#else
let transportDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.2")
]
let transportProduct: Target.Dependency = .product(name: "Alamofire", package: "Alamofire")
#endif

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
    dependencies: transportDependencies,
    targets: [
        .target(
            name: "Tea",
            dependencies: [
                transportProduct
            ]),
        .testTarget(
            name: "TeaTests",
            dependencies: [
                "Tea",
                transportProduct
            ]),
    ],
    swiftLanguageVersions: [.v5]
)
