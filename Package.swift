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
      url: "https://github.com/exception7601/Sentry/releases/download/8.56.0/Sentry-09cd43e66f8179c8.zip",
      checksum: "ecc100b59f2044800650f17786c33f071ea580cb318d82e8ce1d403b643555a4"
    )
  ]
)
