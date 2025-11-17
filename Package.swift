// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Sentry",
  platforms: [.iOS(.v12)],
  products: [
    .library(
      name: "Sentry",
      targets: [
        "Sentry",
      ]
    ),
  ],

  targets: [
    .binaryTarget(
      name: "Sentry",
      url: "https://github.com/exception7601/Sentry/releases/download/8.57.3/Sentry-207ab07e8cdf0857.zip",
      checksum: "a752bc463fc7aafbe7530f6e57b3ca3ac7efcf59a5cd96b863fee9d25f1668fa"
    )
  ]
)
