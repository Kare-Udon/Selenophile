import Foundation

public enum AppLocalization {
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
        case settingsStatusRefreshRateLabel = "settings_status_refresh_rate_label"
        case settingsStatusRefreshRealtime = "settings_status_refresh_realtime"
        case settingsStatusRefreshSecondsFormat = "settings_status_refresh_seconds_format"
        case settingsLaunchAtLoginLabel = "settings_launch_at_login_label"
        case settingsLaunchAtLoginDescription = "settings_launch_at_login_description"
        case settingsLaunchAtLoginUnavailable = "settings_launch_at_login_unavailable"
        case settingsConnectionSection = "settings_connection_section"
        case settingsGeneralSection = "settings_general_section"
        case settingsAppearanceSection = "settings_appearance_section"
        case settingsAdvancedSection = "settings_advanced_section"
        case settingsAboutSection = "settings_about_section"
        case settingsTestConnection = "settings_test_connection"
        case settingsTestingConnection = "settings_testing_connection"
        case settingsConnectionHint = "settings_connection_hint"
        case settingsNoAdditionalOptions = "settings_no_additional_options"
        case settingsAboutBody = "settings_about_body"
        case settingsUpdatesTitle = "settings_updates_title"
        case settingsCheckForUpdates = "settings_check_for_updates"
        case settingsAboutDependenciesTitle = "settings_about_dependencies_title"
        case settingsAboutDependenciesIntro = "settings_about_dependencies_intro"
        case settingsDependencySwift = "settings_dependency_swift"
        case settingsDependencySwiftUI = "settings_dependency_swiftui"
        case settingsDependencyAppKit = "settings_dependency_appkit"
        case settingsDependencyWidgetKit = "settings_dependency_widgetkit"
        case settingsDependencyServiceManagement = "settings_dependency_service_management"
        case settingsDependencyMoonraker = "settings_dependency_moonraker"
        case settingsDependencyTuist = "settings_dependency_tuist"
        case settingsDependencySparkle = "settings_dependency_sparkle"
        case settingsFeatureStatus = "settings_feature_status"
        case settingsFeatureLogs = "settings_feature_logs"
        case settingsFeatureSecurity = "settings_feature_security"
        case settingsConnectionTestSuccess = "settings_connection_test_success"
        case settingsConnectionTestTimeout = "settings_connection_test_timeout"
        case settingsCancel = "settings_cancel"
        case settingsSave = "settings_save"
        case settingsSaving = "settings_saving"
        case followSystem = "follow_system"
        case appearanceModeLabel = "appearance_mode_label"
        case appearanceModeDescription = "appearance_mode_description"
        case appearanceLightMode = "appearance_light_mode"
        case appearanceDarkMode = "appearance_dark_mode"
        case appearanceDefaultNote = "appearance_default_note"
        case themePaletteLabel = "theme_palette_label"
        case themePaletteDescription = "theme_palette_description"
        case themePaletteDefault = "theme_palette_default"
        case themePaletteGraphite = "theme_palette_graphite"
        case themePaletteGitHub = "theme_palette_github"
        case themePaletteTokyoNight = "theme_palette_tokyo_night"
        case themePaletteOneDark = "theme_palette_one_dark"

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
        case menuLastUpdatedPrefix = "menu_last_updated_prefix"
        case menuConnectionBadgeNeedsAttention = "menu_connection_badge_needs_attention"
        case menuConnectionBadgeConnected = "menu_connection_badge_connected"
        case menuConnectionBadgeConnecting = "menu_connection_badge_connecting"
        case menuConnectionBadgeRetrying = "menu_connection_badge_retrying"
        case menuConnectionBadgeDisconnected = "menu_connection_badge_disconnected"
        case menuConnectionBadgeFailed = "menu_connection_badge_failed"
        case menuConnectionBadgeUnconfigured = "menu_connection_badge_unconfigured"
        case connectionSummaryAutoRetryStopped = "connection_summary_auto_retry_stopped"
        case connectionSummaryConnectedWaitingStatus = "connection_summary_connected_waiting_status"
        case connectionSummaryConnectedReceivingStatus = "connection_summary_connected_receiving_status"
        case connectionSummaryConnecting = "connection_summary_connecting"
        case connectionSummaryFailed = "connection_summary_failed"
        case connectionSummaryDisconnected = "connection_summary_disconnected"
        case connectionSummaryUnconfigured = "connection_summary_unconfigured"
        case connectionSummaryRetryFormat = "connection_summary_retry_format"
        case connectionErrorAuthFailed = "connection_error_auth_failed"
        case connectionErrorDecodeMismatch = "connection_error_decode_mismatch"
        case connectionErrorTimeout = "connection_error_timeout"
        case connectionErrorCannotConnect = "connection_error_cannot_connect"
        case connectionErrorCancelled = "connection_error_cancelled"
        case connectionErrorEmptyURL = "connection_error_empty_url"
        case connectionErrorInvalidURL = "connection_error_invalid_url"
        case connectionErrorUnsupportedScheme = "connection_error_unsupported_scheme"
        case cameraErrorNoSnapshotURL = "camera_error_no_snapshot_url"
        case cameraErrorInvalidSnapshotResponse = "camera_error_invalid_snapshot_response"
        case printerStateStandby = "printer_state_standby"
        case printerStatePrinting = "printer_state_printing"
        case printerStatePaused = "printer_state_paused"
        case printerStateComplete = "printer_state_complete"
        case printerStateCancelled = "printer_state_cancelled"
        case printerStateError = "printer_state_error"
        case printerStateUnknown = "printer_state_unknown"
        case widgetTitleNoPrintTask = "widget_title_no_print_task"
        case widgetTitleConnecting = "widget_title_connecting"
        case widgetTitleReconnecting = "widget_title_reconnecting"
        case widgetTitleDisconnected = "widget_title_disconnected"
        case widgetTitleFailed = "widget_title_failed"
        case widgetTitleUnconfigured = "widget_title_unconfigured"
        case widgetSummaryPrintingNormal = "widget_summary_printing_normal"
        case widgetSummaryPaused = "widget_summary_paused"
        case widgetSummaryComplete = "widget_summary_complete"
        case widgetSummaryCancelled = "widget_summary_cancelled"
        case widgetSummaryError = "widget_summary_error"
        case widgetSummaryStandby = "widget_summary_standby"
        case widgetSummaryCheckConnection = "widget_summary_check_connection"
        case widgetSummaryUnconfigured = "widget_summary_unconfigured"
        case widgetDescription = "widget_description"

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
                return "Enter your Moonraker URL, optional token, and camera snapshot URL. Use Test Connection to verify it before saving."
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
            case .settingsStatusRefreshRateLabel:
                return "Status Refresh Rate"
            case .settingsStatusRefreshRealtime:
                return "Realtime"
            case .settingsStatusRefreshSecondsFormat:
                return "%d seconds"
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
            case .settingsTestingConnection:
                return "Testing…"
            case .settingsConnectionHint:
                return "Enter the URLs and token to connect to your Moonraker instance."
            case .settingsNoAdditionalOptions:
                return "No additional options in this section yet."
            case .settingsAboutBody:
                return "Selenophile delivers a refined, at-a-glance overview of your 3D prints with real-time status and camera previews."
            case .settingsUpdatesTitle:
                return "Software Updates"
            case .settingsCheckForUpdates:
                return "Check for Updates…"
            case .settingsAboutDependenciesTitle:
                return "Dependencies"
            case .settingsAboutDependenciesIntro:
                return "Selenophile is built on Apple frameworks, the Swift toolchain, Moonraker API integration, Sparkle for updates, and Tuist for project generation."
            case .settingsDependencySwift:
                return "Language, standard library, package manifest, and command-line build/test workflow."
            case .settingsDependencySwiftUI:
                return "Declarative views for the menu panel, settings window, logs, and widgets."
            case .settingsDependencyAppKit:
                return "macOS menu bar integration, popovers, windows, and native controls."
            case .settingsDependencyWidgetKit:
                return "Publishes the current printer snapshot to macOS widgets."
            case .settingsDependencyServiceManagement:
                return "Controls the Launch at Login setting through macOS login item APIs."
            case .settingsDependencyMoonraker:
                return "Provides the printer status, metadata, thumbnails, and camera data consumed by Selenophile."
            case .settingsDependencyTuist:
                return "Generates and maintains the Xcode project used for app and widget packaging."
            case .settingsDependencySparkle:
                return "Provides secure app update checks and appcast-based distribution."
            case .settingsFeatureStatus:
                return "Monitor progress, temps, layers, and speed"
            case .settingsFeatureLogs:
                return "Quick access to logs and settings"
            case .settingsFeatureSecurity:
                return "Secure connection to your Moonraker instance"
            case .settingsConnectionTestSuccess:
                return "Connection test succeeded."
            case .settingsConnectionTestTimeout:
                return "Connection test timed out."
            case .settingsCancel:
                return "Cancel"
            case .settingsSave:
                return "Save"
            case .settingsSaving:
                return "Saving…"
            case .followSystem:
                return "Follow System"
            case .appearanceModeLabel:
                return "Theme"
            case .appearanceModeDescription:
                return "Choose whether Selenophile follows macOS or uses a fixed light or dark appearance."
            case .appearanceLightMode:
                return "Light"
            case .appearanceDarkMode:
                return "Dark"
            case .appearanceDefaultNote:
                return "Dark remains the default for new installs until you choose another theme."
            case .themePaletteLabel:
                return "Color Style"
            case .themePaletteDescription:
                return "Choose the accent and surface palette used across Selenophile."
            case .themePaletteDefault:
                return "Default"
            case .themePaletteGraphite:
                return "Graphite"
            case .themePaletteGitHub:
                return "GitHub"
            case .themePaletteTokyoNight:
                return "Tokyo Night"
            case .themePaletteOneDark:
                return "One Dark"
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
            case .menuLastUpdatedPrefix:
                return "Last updated"
            case .menuConnectionBadgeNeedsAttention:
                return "Needs Attention"
            case .menuConnectionBadgeConnected:
                return "Connected"
            case .menuConnectionBadgeConnecting:
                return "Connecting"
            case .menuConnectionBadgeRetrying:
                return "Retrying"
            case .menuConnectionBadgeDisconnected:
                return "Disconnected"
            case .menuConnectionBadgeFailed:
                return "Failed"
            case .menuConnectionBadgeUnconfigured:
                return "Not Set Up"
            case .connectionSummaryAutoRetryStopped:
                return "Automatic retry stopped. Reconnect manually."
            case .connectionSummaryConnectedWaitingStatus:
                return "Connected. Waiting for the first status update."
            case .connectionSummaryConnectedReceivingStatus:
                return "Connected and receiving Moonraker status."
            case .connectionSummaryConnecting:
                return "Connecting to Moonraker"
            case .connectionSummaryFailed:
                return "Connection failed"
            case .connectionSummaryDisconnected:
                return "Connection disconnected"
            case .connectionSummaryUnconfigured:
                return "Enter a Moonraker address first."
            case .connectionSummaryRetryFormat:
                return "%@, retrying in %d seconds (%d/%d)"
            case .connectionErrorAuthFailed:
                return "Moonraker authentication failed. Check the JWT or API token."
            case .connectionErrorDecodeMismatch:
                return "Moonraker returned data that does not match the current parser."
            case .connectionErrorTimeout:
                return "Connection to Moonraker timed out."
            case .connectionErrorCannotConnect:
                return "Cannot connect to Moonraker. Check the address, port, or network."
            case .connectionErrorCancelled:
                return "Connection was cancelled."
            case .connectionErrorEmptyURL:
                return "Enter a Moonraker address."
            case .connectionErrorInvalidURL:
                return "The Moonraker address is invalid."
            case .connectionErrorUnsupportedScheme:
                return "The Moonraker address only supports http or https."
            case .cameraErrorNoSnapshotURL:
                return "Enter an accessible camera snapshot URL first."
            case .cameraErrorInvalidSnapshotResponse:
                return "The camera snapshot response is invalid."
            case .printerStateStandby:
                return "Standby"
            case .printerStatePrinting:
                return "Printing"
            case .printerStatePaused:
                return "Paused"
            case .printerStateComplete:
                return "Complete"
            case .printerStateCancelled:
                return "Cancelled"
            case .printerStateError:
                return "Error"
            case .printerStateUnknown:
                return "Unknown"
            case .widgetTitleNoPrintTask:
                return "No current print job"
            case .widgetTitleConnecting:
                return "Connecting to Moonraker"
            case .widgetTitleReconnecting:
                return "Reconnecting to Moonraker"
            case .widgetTitleDisconnected:
                return "Moonraker disconnected"
            case .widgetTitleFailed:
                return "Moonraker connection issue"
            case .widgetTitleUnconfigured:
                return "Set up a Moonraker address first"
            case .widgetSummaryPrintingNormal:
                return "Printing is stable and status is normal"
            case .widgetSummaryPaused:
                return "Print is paused"
            case .widgetSummaryComplete:
                return "Print is complete"
            case .widgetSummaryCancelled:
                return "Print was cancelled"
            case .widgetSummaryError:
                return "Printer status needs attention"
            case .widgetSummaryStandby:
                return "Printer is connected with no active job"
            case .widgetSummaryCheckConnection:
                return "Check the Moonraker address or network connection"
            case .widgetSummaryUnconfigured:
                return "No printer status data is available yet"
            case .widgetDescription:
                return "Display Moonraker print status."
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

    public static func localizedConnectionErrorDescription(_ error: Error, language: AppLanguage) -> String {
        switch error {
        case MoonrakerConfigurationError.emptyURL:
            return localizedString(.connectionErrorEmptyURL, language: language)
        case MoonrakerConfigurationError.invalidURL:
            return localizedString(.connectionErrorInvalidURL, language: language)
        case MoonrakerConfigurationError.unsupportedScheme:
            return localizedString(.connectionErrorUnsupportedScheme, language: language)
        case MoonrakerCameraError.noSnapshotURL:
            return localizedString(.cameraErrorNoSnapshotURL, language: language)
        case MoonrakerCameraError.invalidSnapshotResponse:
            return localizedString(.cameraErrorInvalidSnapshotResponse, language: language)
        default:
            return localizedConnectionErrorMessage(error.localizedDescription, language: language)
        }
    }

    public static func localizedConnectionErrorMessage(_ message: String, language: AppLanguage) -> String {
        let normalized = message.lowercased()

        if normalized.contains("failed to decode jwt") || normalized.contains("jwt") {
            return localizedString(.connectionErrorAuthFailed, language: language)
        }
        if normalized.contains("couldn't be read")
            || normalized.contains("couldn’t be read")
            || normalized.contains("could not be read")
            || normalized.contains("isn’t in the correct format")
            || normalized.contains("isn't in the correct format")
            || normalized.contains("is in the wrong format")
        {
            return localizedString(.connectionErrorDecodeMismatch, language: language)
        }
        if normalized.contains("timed out") || normalized.contains("连接 moonraker 超时") {
            return localizedString(.connectionErrorTimeout, language: language)
        }
        if normalized.contains("could not connect")
            || normalized.contains("cannot connect")
            || normalized.contains("network is unreachable")
            || normalized.contains("connection refused")
            || normalized.contains("无法连接到 moonraker")
        {
            return localizedString(.connectionErrorCannotConnect, language: language)
        }
        if normalized.contains("cancelled") || normalized.contains("canceled") || normalized.contains("已取消") {
            return localizedString(.connectionErrorCancelled, language: language)
        }
        if normalized.contains("请输入 moonraker 地址") || normalized.contains("enter a moonraker address") {
            return localizedString(.connectionErrorEmptyURL, language: language)
        }
        if normalized.contains("moonraker 地址无效") || normalized.contains("moonraker address is invalid") {
            return localizedString(.connectionErrorInvalidURL, language: language)
        }
        if normalized.contains("moonraker 地址只支持") || normalized.contains("moonraker address only supports") {
            return localizedString(.connectionErrorUnsupportedScheme, language: language)
        }
        if normalized.contains("请先填写可访问的相机快照地址") || normalized.contains("accessible camera snapshot url") {
            return localizedString(.cameraErrorNoSnapshotURL, language: language)
        }
        if normalized.contains("相机快照响应无效") || normalized.contains("camera snapshot response is invalid") {
            return localizedString(.cameraErrorInvalidSnapshotResponse, language: language)
        }
        return message
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
        .module
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
