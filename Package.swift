// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGitX",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .visionOS(.v1),
        .watchOS(.v6),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftGitX",
            targets: ["SwiftGitX"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ibrahimcetin/libgit2.git", branch: "v1.9.2")
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
