import ProjectDescription

let project = Project(
    name: "Selenophile",
    organizationName: "udon",
    packages: [
        .remote(
            url: "https://github.com/sparkle-project/Sparkle",
            requirement: .upToNextMajor(from: "2.9.1")
        ),
    ],
    settings: .settings(
        base: [
            "MACOSX_DEPLOYMENT_TARGET": "14.0",
            "SPARKLE_FEED_URL": "https://kare-udon.github.io/Selenophile/selenophile/appcast.xml",
            "SPARKLE_PUBLIC_ED_KEY": "E/nueJJiuhX7I3zRZEjCtYn50JepeMIbY1LltoIs6rA=",
        ]
    ),
    targets: [
        .target(
            name: "SelenophileKit",
            destinations: .macOS,
            product: .staticLibrary,
            bundleId: "com.udon.selenophile.SelenophileKit",
            deploymentTargets: .macOS("14.0"),
            sources: ["Sources/SelenophileKit/**"],
            resources: ["Sources/SelenophileKit/Resources/**"]
        ),
        .target(
            name: "Selenophile",
            destinations: .macOS,
            product: .app,
            bundleId: "com.udon.selenophile",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(
                with: [
                    "LSUIElement": true,
                    "CFBundleDisplayName": "Selenophile",
                    "SUFeedURL": "$(SPARKLE_FEED_URL)",
                    "SUPublicEDKey": "$(SPARKLE_PUBLIC_ED_KEY)",
                    "SUEnableAutomaticChecks": true,
                    "SUScheduledCheckInterval": 86_400,
                ]
            ),
            sources: ["Sources/Selenophile/**"],
            resources: ["Sources/Selenophile/Resources/**"],
            dependencies: [
                .target(name: "SelenophileKit"),
                .package(product: "Sparkle", type: .runtime),
            ]
        ),
        .target(
            name: "SelenophileWidgetExtension",
            destinations: .macOS,
            product: .appExtension,
            bundleId: "com.udon.selenophile.widget",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "Selenophile Widget",
                    "NSExtension": [
                        "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                        "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).SelenophileWidgetBundle",
                    ],
                ]
            ),
            sources: ["Sources/SelenophileWidgetExtension/**"],
            entitlements: .file(path: "SelenophileWidgetExtension.entitlements"),
            dependencies: [
                .target(name: "SelenophileKit"),
            ]
        ),
        .target(
            name: "SelenophileKitTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.udon.selenophile.SelenophileKitTests",
            deploymentTargets: .macOS("14.0"),
            sources: ["Tests/SelenophileKitTests/**"],
            dependencies: [
                .target(name: "SelenophileKit"),
            ]
        ),
        .target(
            name: "SelenophileTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.udon.selenophile.SelenophileTests",
            deploymentTargets: .macOS("14.0"),
            sources: ["Tests/SelenophileTests/**"],
            dependencies: [
                .target(name: "Selenophile"),
            ]
        ),
    ]
)
