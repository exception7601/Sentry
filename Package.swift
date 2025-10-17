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
      url: "https://github.com/exception7601/Sentry/releases/download/8.57.0/Sentry-0add0b562af8fdc4.zip",
      checksum: "2e7948d8fac8b7dfbcc24117c2ae02e79757a49ff3dfb15a06866fc405134a38"
    )
  ]
)
