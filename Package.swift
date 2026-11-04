// swift-tools-version:5.9
import PackageDescription

// The app target needs macOS 14. Linux CI and `swift test` only build the
// logic module; an empty platform list lets that succeed here.
#if os(macOS)
let packagePlatforms: [SupportedPlatform] = [.macOS(.v14)]
#else
let packagePlatforms: [SupportedPlatform]? = nil
#endif

let package = Package(
    name: "EurekaPuzzles",
    platforms: packagePlatforms,
    products: [
        .library(name: "EurekaCore", targets: ["EurekaCore"]),
        .executable(name: "EurekaPuzzles", targets: ["EurekaPuzzles"]),
    ],
    targets: [
        .target(name: "EurekaCore"),
        .executableTarget(
            name: "EurekaPuzzles",
            dependencies: ["EurekaCore"],
            linkerSettings: [
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
                .linkedFramework("SwiftUI", .when(platforms: [.macOS])),
            ]
        ),
        .testTarget(
            name: "EurekaCoreTests",
            dependencies: ["EurekaCore"]
        ),
    ]
)
