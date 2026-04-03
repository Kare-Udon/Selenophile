import ProjectDescription

let project = Project(
    name: "Selenophile",
    organizationName: "udon",
    settings: .settings(
        base: [
            "MACOSX_DEPLOYMENT_TARGET": "14.0",
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
                ]
            ),
            sources: ["Sources/Selenophile/**"],
            dependencies: [
                .target(name: "SelenophileKit"),
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
