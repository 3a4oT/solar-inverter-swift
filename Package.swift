// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "solar-inverter-swift",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .macCatalyst(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(name: "SolarCore", targets: ["SolarCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/3a4oT/solarman-swift.git", from: "1.0.1"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.0"),
    ],
    targets: [
        // MARK: - SolarCore (Multi-vendor Solar Inverter Library)

        .target(
            name: "SolarCore",
            dependencies: [
                .product(name: "SolarmanV5", package: "solarman-swift"),
                .product(name: "Yams", package: "Yams"),
            ],
            resources: [
                .copy("Profiles/Resources"),
            ],
        ),

        // MARK: - Tests

        .testTarget(
            name: "SolarCoreTests",
            dependencies: ["SolarCore"],
        ),
    ],
)
