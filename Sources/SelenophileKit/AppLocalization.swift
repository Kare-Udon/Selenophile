import Foundation

public enum AppLocalization {
    private final class BundleToken {}

    public enum Key: String, CaseIterable, Sendable {
        case settingsWindowTitle = "settings_window_title"
        case logWindowTitle = "log_window_title"
        case fallbackProbeTitle = "fallback_probe_title"
        case settingsHeroBadge = "settings_hero_badge"
        case settingsHeroTitle = "settings_hero_title"
        case settingsHeroSubtitle = "settings_hero_subtitle"
        case settingsMoonrakerURLLabel = "settings_moonraker_url_label"
        case settingsMoonrakerURLPlaceholder = "settings_moonraker_url_placeholder"
        case settingsAPITokenLabel = "settings_api_token_label"
        case settingsAPITokenPlaceholder = "settings_api_token_placeholder"
        case settingsCameraSnapshotURLLabel = "settings_camera_snapshot_url_label"
        case settingsCameraSnapshotURLPlaceholder = "settings_camera_snapshot_url_placeholder"
        case settingsCameraSnapshotHelp = "settings_camera_snapshot_help"
        case settingsLanguageLabel = "settings_language_label"
        case settingsLaunchAtLoginLabel = "settings_launch_at_login_label"
        case settingsLaunchAtLoginDescription = "settings_launch_at_login_description"
        case settingsLaunchAtLoginUnavailable = "settings_launch_at_login_unavailable"
        case settingsConnectionSection = "settings_connection_section"
        case settingsGeneralSection = "settings_general_section"
        case settingsAppearanceSection = "settings_appearance_section"
        case settingsAdvancedSection = "settings_advanced_section"
        case settingsAboutSection = "settings_about_section"
        case settingsTestConnection = "settings_test_connection"
        case settingsConnectionHint = "settings_connection_hint"
        case settingsNoAdditionalOptions = "settings_no_additional_options"
        case settingsAboutBody = "settings_about_body"
        case settingsCancel = "settings_cancel"
        case settingsSave = "settings_save"
        case settingsSaving = "settings_saving"
        case followSystem = "follow_system"

        case menuLivePrint = "menu_live_print"
        case menuTask = "menu_task"
        case menuReconnect = "menu_reconnect"
        case menuOpenLogs = "menu_open_logs"
        case menuOpenSettings = "menu_open_settings"
        case menuQuit = "menu_quit"
        case menuRefresh = "menu_refresh"
        case menuRefreshing = "menu_refreshing"
        case menuCameraSnapshot = "menu_camera_snapshot"
        case menuNeedConfigForCameraSnapshot = "menu_need_config_for_camera_snapshot"
        case menuFetchingCameraSnapshot = "menu_fetching_camera_snapshot"
        case menuRefreshToGetSnapshot = "menu_refresh_to_get_snapshot"
        case menuElapsedTime = "menu_elapsed_time"
        case menuRemainingTime = "menu_remaining_time"
        case menuNozzle = "menu_nozzle"
        case menuBed = "menu_bed"
        case menuLayer = "menu_layer"
        case menuPrintSpeed = "menu_print_speed"
        case menuViewThumbnailAccessibility = "menu_view_thumbnail_accessibility"
        case menuViewTaskNameAccessibility = "menu_view_task_name_accessibility"
        case menuNoPrintTask = "menu_no_print_task"
        case menuThumbnailPlaceholderFetching = "menu_thumbnail_placeholder_fetching"
        case menuThumbnailPlaceholderRetry = "menu_thumbnail_placeholder_retry"
        case menuThumbnailPlaceholderEmpty = "menu_thumbnail_placeholder_empty"
        case menuPrintThumbnailTitle = "menu_print_thumbnail_title"
        case menuNoThumbnailPreview = "menu_no_thumbnail_preview"
        case menuTaskFullName = "menu_task_full_name"
        case menuCopySelectableText = "menu_copy_selectable_text"
        case menuTooltipTitle = "menu_tooltip_title"
        case menuTooltipStatus = "menu_tooltip_status"
        case menuTooltipProgress = "menu_tooltip_progress"

        case logLevelDebug = "log_level_debug"
        case logLevelInfo = "log_level_info"
        case logLevelWarning = "log_level_warning"
        case logLevelError = "log_level_error"
        case logHeaderTitle = "log_header_title"
        case logHeaderSubtitle = "log_header_subtitle"
        case logLevelLabel = "log_level_label"
        case logCopyAll = "log_copy_all"
        case logClear = "log_clear"
        case logEmptyStateTitle = "log_empty_state_title"
        case logEmptyStateSubtitle = "log_empty_state_subtitle"
        case logFilteredEmptyStateTitle = "log_filtered_empty_state_title"
        case logFilteredEmptyStateSubtitle = "log_filtered_empty_state_subtitle"
        case logCountZero = "log_count_zero"
        case logCountTotal = "log_count_total"
        case logCountVisible = "log_count_visible"
        case logTimeColumn = "log_time_column"
        case logSourceColumn = "log_source_column"
        case logMessageColumn = "log_message_column"

        var fallbackValue: String {
            switch self {
            case .settingsWindowTitle:
                return "Moonraker Settings"
            case .logWindowTitle:
                return "Debug Logs"
            case .fallbackProbeTitle:
                return "Fallback Probe"
            case .settingsHeroBadge:
                return "Moonraker Setup"
            case .settingsHeroTitle:
                return "Connect your print status source"
            case .settingsHeroSubtitle:
                return "Enter your Moonraker URL, optional token, and camera snapshot URL. Saving tests the connection."
            case .settingsMoonrakerURLLabel:
                return "Moonraker URL"
            case .settingsMoonrakerURLPlaceholder:
                return "http://127.0.0.1:7125"
            case .settingsAPITokenLabel:
                return "API Token (optional)"
            case .settingsAPITokenPlaceholder:
                return "JWT or API key"
            case .settingsCameraSnapshotURLLabel:
                return "Camera Snapshot URL"
            case .settingsCameraSnapshotURLPlaceholder:
                return "http://127.0.0.1/webcam/?action=snapshot"
            case .settingsCameraSnapshotHelp:
                return "Enter a direct image URL. Absolute URLs and relative paths on the Moonraker host are supported."
            case .settingsLanguageLabel:
                return "Interface Language"
            case .settingsLaunchAtLoginLabel:
                return "Launch at Login"
            case .settingsLaunchAtLoginDescription:
                return "When enabled, the app opens automatically at system login."
            case .settingsLaunchAtLoginUnavailable:
                return "Currently unavailable"
            case .settingsConnectionSection:
                return "Connection"
            case .settingsGeneralSection:
                return "General"
            case .settingsAppearanceSection:
                return "Appearance"
            case .settingsAdvancedSection:
                return "Advanced"
            case .settingsAboutSection:
                return "About"
            case .settingsTestConnection:
                return "Test Connection"
            case .settingsConnectionHint:
                return "Enter the URLs and token to connect to your Moonraker instance."
            case .settingsNoAdditionalOptions:
                return "No additional options in this section yet."
            case .settingsAboutBody:
                return "Selenophile delivers a refined, at-a-glance overview of your 3D prints with real-time status, camera previews, and detailed debugging tools."
            case .settingsCancel:
                return "Cancel"
            case .settingsSave:
                return "Test Connection and Save"
            case .settingsSaving:
                return "Connecting…"
            case .followSystem:
                return "Follow System"
            case .menuLivePrint:
                return "Live Print"
            case .menuTask:
                return "Task"
            case .menuReconnect:
                return "Reconnect"
            case .menuOpenLogs:
                return "Logs"
            case .menuOpenSettings:
                return "Settings"
            case .menuQuit:
                return "Quit"
            case .menuRefresh:
                return "Refresh"
            case .menuRefreshing:
                return "Fetching…"
            case .menuCameraSnapshot:
                return "Camera Snapshot"
            case .menuNeedConfigForCameraSnapshot:
                return "Complete Moonraker setup first"
            case .menuFetchingCameraSnapshot:
                return "Fetching camera snapshot"
            case .menuRefreshToGetSnapshot:
                return "Refresh to get a snapshot"
            case .menuElapsedTime:
                return "Elapsed Time"
            case .menuRemainingTime:
                return "Remaining Time"
            case .menuNozzle:
                return "Nozzle"
            case .menuBed:
                return "Bed"
            case .menuLayer:
                return "Layer"
            case .menuPrintSpeed:
                return "Print Speed"
            case .menuViewThumbnailAccessibility:
                return "View print thumbnail"
            case .menuViewTaskNameAccessibility:
                return "View full task name"
            case .menuNoPrintTask:
                return "No current print job"
            case .menuThumbnailPlaceholderFetching:
                return "Thumbnail"
            case .menuThumbnailPlaceholderRetry:
                return "Retry"
            case .menuThumbnailPlaceholderEmpty:
                return "No thumbnail"
            case .menuPrintThumbnailTitle:
                return "Print Thumbnail"
            case .menuNoThumbnailPreview:
                return "No print thumbnail available to preview"
            case .menuTaskFullName:
                return "Task Full Name"
            case .menuCopySelectableText:
                return "Copy selectable text"
            case .menuTooltipTitle:
                return "Selenophile"
            case .menuTooltipStatus:
                return "Status"
            case .menuTooltipProgress:
                return "Progress"
            case .logLevelDebug:
                return "Debug"
            case .logLevelInfo:
                return "Info"
            case .logLevelWarning:
                return "Warning"
            case .logLevelError:
                return "Error"
            case .logHeaderTitle:
                return "Debug Logs"
            case .logHeaderSubtitle:
                return "Show connection, retry, status update, and camera request logs."
            case .logLevelLabel:
                return "Log Level"
            case .logCopyAll:
                return "Copy All"
            case .logClear:
                return "Clear"
            case .logEmptyStateTitle:
                return "No logs yet"
            case .logEmptyStateSubtitle:
                return "Logs will appear here after the app starts recording connection or camera events."
            case .logFilteredEmptyStateTitle:
                return "No logs at this level"
            case .logFilteredEmptyStateSubtitle:
                return "Raise the minimum level to see more entries."
            case .logCountZero:
                return "Total 0 entries"
            case .logCountTotal:
                return "Total %lld entries"
            case .logCountVisible:
                return "Showing %lld / %lld entries"
            case .logTimeColumn:
                return "Time"
            case .logSourceColumn:
                return "Source"
            case .logMessageColumn:
                return "Message"
            }
        }
    }

    public static func localizedString(_ key: Key, language: AppLanguage) -> String {
        localizedString(key.rawValue, fallback: key.fallbackValue, language: language)
    }

    public static func locale(for language: AppLanguage) -> Locale {
        let resolvedLanguage = language.resolved()
        return Locale(identifier: resolvedLanguage.localeIdentifier ?? AppLanguage.english.rawValue)
    }

    public static func settingsWindowTitle(for language: AppLanguage) -> String {
        localizedString(.settingsWindowTitle, language: language)
    }

    public static func logWindowTitle(for language: AppLanguage) -> String {
        localizedString(.logWindowTitle, language: language)
    }

    static func localizedString(_ key: String, fallback: String, language: AppLanguage) -> String {
        localizedString(
            key,
            fallback: fallback,
            language: language,
            candidateBundles: defaultCandidateBundles()
        )
    }

    static func localizedString(
        _ key: String,
        fallback: String,
        language: AppLanguage,
        candidateBundles: [Bundle]
    ) -> String {
        let resolvedLanguage = language.resolved()
        let bundle = localizedBundle(for: resolvedLanguage, candidateBundles: candidateBundles)
        let localized = bundle.localizedString(forKey: key, value: fallback, table: nil)

        if localized != key {
            return localized
        }

        if resolvedLanguage != .english {
            let fallbackBundle = localizedBundle(for: .english, candidateBundles: candidateBundles)
            let fallbackValue = fallbackBundle.localizedString(forKey: key, value: fallback, table: nil)
            if fallbackValue != key {
                return fallbackValue
            }
        }

        return fallback
    }

    private static func localizedBundle(for language: AppLanguage, candidateBundles: [Bundle]) -> Bundle {
        let identifier = language.localeIdentifier ?? AppLanguage.english.rawValue
        let candidates = identifier == identifier.lowercased()
            ? [identifier]
            : [identifier, identifier.lowercased()]

        for candidate in candidates {
            if let bundle = bundle(forLocalization: candidate, candidateBundles: candidateBundles) {
                return bundle
            }
        }

        if identifier != AppLanguage.english.rawValue,
           let bundle = bundle(forLocalization: AppLanguage.english.rawValue, candidateBundles: candidateBundles) {
            return bundle
        }
        return localizationBaseBundle()
    }

    private static func bundle(forLocalization localization: String, candidateBundles: [Bundle]) -> Bundle? {
        for bundle in expandedCandidateBundles(from: candidateBundles) {
            guard let url = bundle.url(forResource: localization, withExtension: "lproj") else {
                continue
            }
            if let localizedBundle = Bundle(url: url) {
                return localizedBundle
            }
        }

        return nil
    }

    private static func localizationBaseBundle() -> Bundle {
#if SWIFT_PACKAGE
        return .module
#else
        return Bundle(for: BundleToken.self)
#endif
    }

    private static func defaultCandidateBundles() -> [Bundle] {
        [localizationBaseBundle(), Bundle.main]
    }

    private static func expandedCandidateBundles(from roots: [Bundle]) -> [Bundle] {
        var visited = Set<URL>()
        var bundles: [Bundle] = []

        for root in roots {
            appendBundle(root, to: &bundles, visited: &visited)

            guard let resourceURL = root.resourceURL else { continue }
            let nestedBundleURLs = (try? FileManager.default.contentsOfDirectory(
                at: resourceURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )) ?? []

            for nestedURL in nestedBundleURLs where nestedURL.pathExtension == "bundle" {
                guard let nestedBundle = Bundle(url: nestedURL) else { continue }
                appendBundle(nestedBundle, to: &bundles, visited: &visited)
            }
        }

        return bundles
    }

    private static func appendBundle(_ bundle: Bundle, to bundles: inout [Bundle], visited: inout Set<URL>) {
        let bundleURL = bundle.bundleURL.standardizedFileURL
        guard visited.insert(bundleURL).inserted else {
            return
        }
        bundles.append(bundle)
    }
}
