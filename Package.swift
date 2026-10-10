// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Linux) && compiler(<5.8)
#error("Tea on Linux requires Swift 5.8 or later.")
#endif

#if os(Linux)
#if compiler(<5.9)
// Newer releases require Swift 5.9 or use newer SwiftPM APIs in their manifests.
let transportDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/swift-server/async-http-client.git", "1.21.0"..<"1.24.1"),
    .package(url: "https://github.com/apple/swift-nio-transport-services.git", "1.19.0"..<"1.24.0"),
    .package(url: "https://github.com/apple/swift-nio-extras.git", "1.13.0"..<"1.25.0")
]
#else
let transportDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.21.0")
]
#endif
let transportProduct: Target.Dependency = .product(name: "AsyncHTTPClient", package: "async-http-client")
#else
let transportDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.2")
]
let transportProduct: Target.Dependency = .product(name: "Alamofire", package: "Alamofire")
#endif

var transportTargetDependencies: [Target.Dependency] = [transportProduct]
#if os(Linux) && compiler(<5.9)
// Keep the version constraints when Tea is used as a transitive dependency.
transportTargetDependencies += [
    .product(name: "NIOHTTPCompression", package: "swift-nio-extras"),
    .product(name: "NIOTransportServices", package: "swift-nio-transport-services")
]
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
            dependencies: transportTargetDependencies),
        .testTarget(
            name: "TeaTests",
            dependencies: [
                "Tea",
                transportProduct
            ]),
    ],
    swiftLanguageVersions: [.v5]
)
