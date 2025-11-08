# SwiftGitX
[![CI](https://github.com/ibrahimcetin/SwiftGitX/actions/workflows/swift.yml/badge.svg)](https://github.com/ibrahimcetin/SwiftGitX/actions/workflows/swift.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fibrahimcetin%2FSwiftGitX%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ibrahimcetin/SwiftGitX)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fibrahimcetin%2FSwiftGitX%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ibrahimcetin/SwiftGitX)

Welcome to SwiftGitX! 🎉

SwiftGitX is a modern Swift wrapper for [libgit2](https://libgit2.org). It's designed to make working with Git in Swift easy and efficient. Plus, it fully supports the [Swift Package Manager](https://github.com/swiftlang/swift-package-manager) and has no external dependencies.

```swift
let url = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
let repository = try await Repository.clone(from: url, to: URL(string: "/path/to/clone")!)

let latestCommit = try repository.HEAD.target as? Commit

let main = try repository.branch.get(named: "main")
let feature = try repository.branch.create(named: "feature", from: main)
try repository.switch(to: feature)
```

## Why Choose SwiftGitX?

SwiftGitX offers:

- **Swift concurrency support**: Take advantage of async/await for smooth, non-blocking Git operations.
- **Throwing functions**: Handle errors gracefully with Swift's error handling.
- **Full SPM support**: Easily integrate SwiftGitX into your projects.
- **Intuitive design**: A user-friendly API that's similar to the Git command line interface, making it easy to learn and use.
- **Wrapper, not just bindings**: SwiftGitX provides a complete Swift experience with no low-level C functions or types. It also includes modern Git commands, offering more functionality than other libraries.

## Adding SwiftGitX to Your Project

To get started, just add SwiftGitX to your project:

1. File > Add Package Dependencies...
2. Enter https://github.com/ibrahimcetin/SwiftGitX.git
3. Select "Up to Next Major" with "0.1.0"

Or add SwiftGitX to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/ibrahimcetin/SwiftGitX.git", from: "0.1.0"),
]
```

## Documentation

The documentation for `releases` and `main` are available here:

* [0.x.x](https://swiftpackageindex.com/ibrahimcetin/SwiftGitX/~/documentation/SwiftGitX)
* [`main`](https://swiftpackageindex.com/ibrahimcetin/SwiftGitX/main/documentation/SwiftGitX)

## Building and Testing

SwiftGitX is easy to build and test. It requires only Swift, no additional system dependencies.
To build SwiftGitX, run:
```bash
swift build
```
To test SwiftGitX, run:
```bash
swift test
```

## Contributing

We welcome contributions! Whether you want to report a bug, request a feature, improve documentation, or add tests, we appreciate your help.

**For developers**, when contributing, please ensure to add appropriate tests and documentation to keep our project robust and well-documented.

---

Thank you for considering SwiftGitX for your project. I'm excited to see what you’ll build! 😊

---

Feel free to let me know if there's anything specific you'd like to adjust further! 🚀
