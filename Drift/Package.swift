// swift-tools-version: 5.9
// This file is used to declare Supabase as a dependency.
// In Xcode: File → Add Package Dependencies → paste the Supabase URL.

import PackageDescription

let package = Package(
    name: "Drift",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Drift", targets: ["Drift"])
    ],
    dependencies: [
        // Supabase Swift SDK
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "Drift",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ]
        ),
    ]
)
