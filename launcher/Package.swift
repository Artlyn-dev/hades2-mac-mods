// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Hades2Mods",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Hades2Mods", targets: ["Hades2Mods"]),
    ],
    targets: [
        .executableTarget(
            name: "Hades2Mods"
        ),
    ]
)
