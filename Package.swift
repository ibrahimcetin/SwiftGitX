// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGitX",
    platforms: [
        .macOS(.v11),
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftGitX",
            targets: ["SwiftGitX"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ibrahimcetin/libgit2.git", from: "1.9.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftGitX",
            dependencies: ["libgit2"]
        ),
        .testTarget(
            name: "SwiftGitXTests",
            dependencies: ["SwiftGitX"]
        )
    ]
)
