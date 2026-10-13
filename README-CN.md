[English](./README.md) | 简体中文

![](https://aliyunsdk-pages.alicdn.com/icons/AlibabaCloud.svg)

## Alibaba Cloud Tea for Swift(5.6)

[![Cocoapod Version](https://img.shields.io/cocoapods/v/Tea)](https://cocoapods.org/pods/Tea)
[![Travis CI Build Status](https://img.shields.io/travis/aliyun/tea-swift?logo=travis)](https://travis-ci.org/aliyun/tea-swift)
[![codecov](https://codecov.io/gh/aliyun/tea-swift/branch/master/graph/badge.svg)](https://codecov.io/gh/aliyun/tea-swift)

## 依赖

- iOS 13.3+ / macOS 10.15+
- Xcode 11.3+
- Apple 平台 Swift 5.6+ / Linux Swift 5.9+

## 安装

### CocoaPods

[CocoaPods](https://cocoapods.org) 是 Cocoa 项目管理工具。请访问其官方网站获取关于 CocoaPods 的使用和安装说明。要使用 CocoaPods 将 `Tea` 集成到你的 Xcode 项目中，需要在 `Podfile` 中定义以下内容:

```ruby
pod 'Tea', '~> 1.0.0'
```

### Carthage

要使用 [Carthage](https://github.com/Carthage/Carthage) 将 Tea 集成到你的 Xcode 项目中，需要在 `Cartfile` 中定义以下内容:

```ogdl
github "aliyun/tea-swift" "1.0.0"
```

### Swift 包管理工具

要使用 [Swift Package Manager](https://swift.org/package-manager/) 将 Tea 集成到你的 Xcode 项目中，请将 Tea 添加至你的 `Package.swift` 文件的 dependencies 数组内容中:

```swift
dependencies: [
    .package(url: "https://github.com/aliyun/tea-swift.git", from: "1.0.0")
]
```

另外，还需要在 `target` 的 `dependencies` 中添加 `"Tea"`，如下：

```swift
.target(
    name: "<your-project-name>",
    dependencies: [
        "Tea",
    ]),
```

## Linux HTTP 诊断

设置环境变量 `TEA_LINUX_TRACE=1` 可确认请求进入 AsyncHTTPClient 传输实现，并在响应读取及客户端关闭完成后输出 HTTP 状态码。例如：

```bash
TEA_LINUX_TRACE=1 swift run <your-executable>
```

日志默认关闭，开启后输出到标准错误，不包含 URL、请求头、请求体或凭证。HTTP 响应完成不代表 API 业务成功，仍需检查返回内容；这些日志也不验证退避重试。

## 问题

[提交 Issue](https://github.com/aliyun/tea-swift/issues/new)，不符合指南的问题可能会立即关闭。

## 发行说明

每个版本的详细更改记录在[发行说明](./ChangeLog.md)中。

## 相关

- [OpenAPI 开发者门户](https://next.api.aliyun.com/)
- [最新源码](https://github.com/aliyun/tea-swift)

## 许可证

[Apache-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Copyright (c) 2009-present, Alibaba Cloud All rights reserved.
