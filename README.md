English | [简体中文](./README-CN.md)

![](https://aliyunsdk-pages.alicdn.com/icons/AlibabaCloud.svg)

## Alibaba Cloud Tea for Swift(5.1)

[![Build Status](https://travis-ci.org/aliyun/tea-swift.svg?branch=master)](https://travis-ci.org/aliyun/tea-swift)

## Requirements

- iOS 13.3+ / macOS 10.15+
- Xcode 11.3+
- Swift 5.1

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate `Tea` into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'Tea', '~> 0.1.0'
```

### Carthage

To integrate `Tea` into your Xcode project using [Carthage](https://github.com/Carthage/Carthage), specify it in your `Cartfile`:

```ogdl
github "aliyun/Tea" "0.1.0"
```

### Swift Package Manager

To integrate `Tea` into your Xcode project using [Swift Package Manager](https://swift.org/package-manager/) , adding `Tea` to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/aliyun/tea-swift.git", from: "0.1.0")
]
```

In addition, you also need to add `"Tea"` to the `dependencies` of the `target`, as follows:

```swift
.target(
    name: "<your-project-name>",
    dependencies: [
        "Tea",
    ])
```

## Issues
[Opening an Issue](https://github.com/aliyun/tea-swift/issues/new), Issues not conforming to the guidelines may be closed immediately.

## Changelog
Detailed changes for each release are documented in the [release notes](./ChangeLog.md).

## References
* [OpenAPI Explorer](https://api.aliyun.com/)
* [Latest Release](https://github.com/aliyun/tea-swift)

## License
[Apache-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Copyright (c) 2009-present, Alibaba Cloud All rights reserved.
