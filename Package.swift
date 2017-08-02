// swift-tools-version:4.0

import PackageDescription

let package = Package(
	name: "Swasm",
	products: [
		.library(
			name: "Swasm",
			targets: ["Swasm"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/Quick/Nimble", from: "7.0.1"),
	],
	targets: [
		.target(
			name: "Swasm",
			dependencies: []
		),
		.testTarget(
			name: "SwasmTests",
			dependencies: ["Swasm", "Nimble"]
		),
	]
)
