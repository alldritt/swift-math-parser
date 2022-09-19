// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-math-parser",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
    products: [.library(name: "MathParser", targets: ["MathParser"])],
    dependencies: [.package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.10.0")],
    targets: [
        .target(
            name: "MathParser",
            dependencies: [.product(name: "Parsing", package: "swift-parsing")]),
        .testTarget(
            name: "MathParserTests",
            dependencies: ["MathParser", .product(name: "Parsing", package: "swift-parsing")]),
    ]
)

#if swift(>=5.6)
// Add the documentation compiler plugin if possible
package.dependencies.append(
  .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
)
#endif
