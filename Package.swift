// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "net-thru",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "net-thru", targets: ["NetThru"]),
    ],
    targets: [
        // Monitoring, formatting and drawing, shared by the app and the README animation.
        .target(name: "NetThruKit"),
        .executableTarget(name: "NetThru", dependencies: ["NetThruKit"]),
        // Renders the README animation (`make demo`).
        .executableTarget(name: "MakeDemo", dependencies: ["NetThruKit"]),
        // Fakes shared by the test targets.
        .target(name: "NetThruTestSupport", dependencies: ["NetThruKit"], path: "Tests/NetThruTestSupport"),
        .testTarget(name: "NetThruKitTests", dependencies: ["NetThruKit", "NetThruTestSupport"]),
        .testTarget(name: "NetThruTests", dependencies: ["NetThru", "NetThruTestSupport"]),
        .testTarget(name: "MakeDemoTests", dependencies: ["MakeDemo"]),
    ]
)
