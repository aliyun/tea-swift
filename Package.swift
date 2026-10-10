// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Linux)
let transport: Package.Dependency = .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.19.0")
let transportProduct: Target.Dependency = .product(name: "AsyncHTTPClient", package: "async-http-client")
#else
let transport: Package.Dependency = .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.2")
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
    dependencies: [
        transport,
    ],
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
