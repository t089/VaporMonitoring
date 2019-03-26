// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "VaporMonitoring",
    products: [
        .library(name: "VaporMonitoring", targets: ["VaporMonitoring"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.3.0"),
        .package(url: "https://github.com/t089/SwiftMetrics.git", .branch("standalone-2")),
    ],
    targets: [
      .target(name: "VaporMonitoring", dependencies: ["Vapor", "SwiftMetrics"]),
      .target(name: "MonitoringExample", dependencies: ["VaporMonitoring"]),
      .testTarget(
        name: "VaporMonitoringTests",
        dependencies: ["VaporMonitoring"]),
    ],
    swiftLanguageVersions: [ 4 ]
)
