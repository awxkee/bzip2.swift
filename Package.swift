// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bzip2.swift",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "bzip2.swift",
            targets: ["bzip2.swift"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "bzip2.swift",
            dependencies: [.target(name: "bzip2.objc")],
            path: "Sources/bzip2.swift"),
        .target(name: "bzip2.objc",
                dependencies: [],
                path: "Sources/bzip2.objc",
                publicHeadersPath: "include",
                cSettings: [
                    .headerSearchPath("."),
                    .headerSearchPath("include"),
                    .define("BZIP_DECLARE_EXPORT")
                ],
                linkerSettings: [
                    .linkedLibrary("bz2")
                ]),
        .testTarget(
            name: "bzip2.swiftTests",
            dependencies: ["bzip2.swift"],
            path: "Tests",
            resources: [.process("bzip2.swiftTests/Test Files/XZ.txt")]),
    ]
)
