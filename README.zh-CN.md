# SwiftGitX
<p align="center"><a href="./README.md">English</a> · <a href="./README.zh-CN.md">简体中文</a> · <a href="./README.ja.md">日本語</a></p>
[![CI](https://github.com/ibrahimcetin/SwiftGitX/actions/workflows/swift.yml/badge.svg)](https://github.com/ibrahimcetin/SwiftGitX/actions/workflows/swift.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fibrahimcetin%2FSwiftGitX%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ibrahimcetin/SwiftGitX)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fibrahimcetin%2FSwiftGitX%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ibrahimcetin/SwiftGitX)

欢迎使用 SwiftGitX！🎉

SwiftGitX 是 [libgit2](https://libgit2.org) 的现代 Swift 封装，旨在让使用 Swift 进行 Git 操作变得简单高效。此外，它完全支持 [Swift Package Manager](https://github.com/swiftlang/swift-package-manager)，且没有外部依赖。

```swift
let url = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
let repository = try await Repository.clone(from: url, to: URL(string: "/path/to/clone")!)

let latestCommit = try repository.HEAD.target as? Commit

let main = try repository.branch.get(named: "main")
let feature = try repository.branch.create(named: "feature", from: main)
try repository.switch(to: feature)
```

## 为什么选择 SwiftGitX？

SwiftGitX 提供：

- **支持 Swift 并发**：利用 async/await 实现流畅的非阻塞 Git 操作。
- **抛出错误的函数**：使用 Swift 的错误处理机制妥善处理错误。
- **完整支持 SPM**：轻松将 SwiftGitX 集成到你的项目中。
- **直观的设计**：易于使用的 API 与 Git 命令行界面相似，便于学习和使用。
- **完整封装，而非简单绑定**：SwiftGitX 提供完整的 Swift 使用体验，不会暴露底层 C 函数或类型。它还包含现代 Git 命令，提供比其他库更丰富的功能。

## 将 SwiftGitX 添加到你的项目

只需将 SwiftGitX 添加到项目中即可开始使用：

1. File > Add Package Dependencies...
2. 输入 https://github.com/ibrahimcetin/SwiftGitX.git
3. 选择 "Up to Next Major"，版本填写 "0.1.0"

也可以将 SwiftGitX 添加到 `Package.swift` 文件：

```swift
dependencies: [
    .package(url: "https://github.com/ibrahimcetin/SwiftGitX.git", from: "0.1.0"),
]
```

## 文档

`releases` 和 `main` 的文档可在此处查阅：

* [0.x.x](https://swiftpackageindex.com/ibrahimcetin/SwiftGitX/~/documentation/SwiftGitX)
* [`main`](https://swiftpackageindex.com/ibrahimcetin/SwiftGitX/main/documentation/SwiftGitX)

## 构建与测试

SwiftGitX 易于构建和测试。它只需要 Swift，无需额外的系统依赖。
运行以下命令构建 SwiftGitX：
```bash
swift build
```
运行以下命令测试 SwiftGitX：
```bash
swift test
```

## 贡献

欢迎贡献！无论你是想报告错误、请求功能、改进文档还是添加测试，我们都感谢你的帮助。

**开发者注意**：贡献代码时，请确保添加适当的测试和文档，以保持项目的健壮性和文档完整性。

---

感谢你考虑在项目中使用 SwiftGitX。期待看到你将用它构建什么！😊

---

如果还有任何想要进一步调整的具体内容，欢迎告诉我！🚀
