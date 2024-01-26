// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VCRemoteCommand",
    platforms: [
        .macOS(.v10_15),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "VCRemoteCommand",
            targets: ["VCRemoteCommandCore"]),
        .executable(name: "SSHCLI", targets: ["CLI", "VCRemoteCommandCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio-ssh", from: "0.8.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "VCRemoteCommandCore",
                dependencies: [.product(name: "NIOSSH", package:"swift-nio-ssh")]
               ),
        .executableTarget(name: "CLI",
                          dependencies: [
                            .target(name: "VCRemoteCommandCore")
                          ])
    ]
)
