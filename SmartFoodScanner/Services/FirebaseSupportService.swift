import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebaseRemoteConfig

enum AppFirebaseRuntime {
    static var isAnalyticsCollectionEnabled: Bool {
        #if DEBUG
        false
        #else
        true
        #endif
    }

    static var isCrashlyticsCollectionEnabled: Bool {
        #if DEBUG
        false
        #else
        true
        #endif
    }

    static func configureCollections() {
        Analytics.setAnalyticsCollectionEnabled(isAnalyticsCollectionEnabled)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(isCrashlyticsCollectionEnabled)
    }
}

enum AppAnalyticsEvent: String {
    case appLaunch = "app_launch"
    case homeViewed = "home_viewed"
    case barcodeScannerOpened = "barcode_scanner_opened"
    case ingredientsScannerOpened = "ingredients_scanner_opened"
    case manualSearchOpened = "manual_search_opened"
    case productResultViewed = "product_result_viewed"
    case historyViewed = "history_viewed"
    case educationViewed = "education_viewed"
    case foodChatOpened = "food_chat_opened"
    case foodChatQuestionAsked = "food_chat_question_asked"
    case settingsViewed = "settings_viewed"
    case termsViewed = "terms_viewed"
    case privacyViewed = "privacy_viewed"
    case supportViewed = "support_viewed"
    case appReviewRequested = "app_review_requested"
    case usdaLookupAttempted = "usda_lookup_attempted"
    case usdaLookupSucceeded = "usda_lookup_succeeded"
    case usdaLookupFailed = "usda_lookup_failed"
    case remoteConfigActivated = "remote_config_activated"
    case attAuthorizationResolved = "att_authorization_resolved"
}

final class AppAnalyticsService {
    static let shared = AppAnalyticsService()

    private init() {}

    func log(_ event: AppAnalyticsEvent, parameters: [String: Any] = [:]) {
        guard AppFirebaseRuntime.isAnalyticsCollectionEnabled else { return }
        Analytics.logEvent(event.rawValue, parameters: parameters)
    }

    func record(_ error: Error, context: String) {
        guard AppFirebaseRuntime.isCrashlyticsCollectionEnabled else { return }
        Crashlytics.crashlytics().setCustomValue(context, forKey: "error_context")
        Crashlytics.crashlytics().record(error: error)
    }
}

final class AppRemoteConfigService {
    static let shared = AppRemoteConfigService()

    private let remoteConfig = RemoteConfig.remoteConfig()
    private var isConfigured = false

    private init() {}

    func configure() {
        guard isConfigured == false else { return }

        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        settings.fetchTimeout = 5
        #else
        settings.minimumFetchInterval = 3600
        settings.fetchTimeout = 10
        #endif

        remoteConfig.configSettings = settings

        // Local fallback only, used before Remote Config's first
        // fetch/activate completes — the real runtime values are whatever
        // you've set in the Remote Config console. Debug builds fall back
        // to Google's public test units; Release falls back to an empty
        // string so a pre-fetch ad request can never accidentally serve
        // Google's test creative to a real user.
#if DEBUG
        let bannerAdUnitDefault = "ca-app-pub-3940256099942544/2934735716"
        let interstitialAdUnitDefault = "ca-app-pub-3940256099942544/4411468910"
#else
        let bannerAdUnitDefault = ""
        let interstitialAdUnitDefault = ""
#endif

        remoteConfig.setDefaults([
            // No real key shipped in source — the production USDA key lives only
            // in the Firebase Remote Config console. USDA's public "DEMO_KEY" is
            // rate-limited but keeps USDA fallback lookups working before the
            // first Remote Config fetch completes (or if fetch ever fails).
            "usda_api_key": "DEMO_KEY" as NSObject,
            "enable_food_ai_chat": true as NSObject,
            "ads_enabled": true as NSObject,
            "banner_ad_unit_id": bannerAdUnitDefault as NSObject,
            "interstitial_ad_unit_id": interstitialAdUnitDefault as NSObject,
            "interstitial_scan_frequency": 4 as NSObject
        ])
        isConfigured = true
    }

    func fetchAndActivate() async {
        await withCheckedContinuation { continuation in
            remoteConfig.fetchAndActivate { status, error in
                if let error {
                    AppAnalyticsService.shared.record(error, context: "remote_config_fetch")
                } else {
                    AppAnalyticsService.shared.log(
                        .remoteConfigActivated,
                        parameters: ["status": String(describing: status)]
                    )
                }
                continuation.resume()
            }
        }
    }

    var usdaAPIKey: String {
        remoteConfig
            .configValue(forKey: "usda_api_key")
            .stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isFoodAIChatEnabled: Bool {
        remoteConfig.configValue(forKey: "enable_food_ai_chat").boolValue
    }

    var areAdsEnabled: Bool {
        remoteConfig.configValue(forKey: "ads_enabled").boolValue
    }

    var bannerAdUnitID: String {
        remoteConfig
            .configValue(forKey: "banner_ad_unit_id")
            .stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var interstitialAdUnitID: String {
        remoteConfig
            .configValue(forKey: "interstitial_ad_unit_id")
            .stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var interstitialScanFrequency: Int {
        let value = remoteConfig.configValue(forKey: "interstitial_scan_frequency").numberValue.intValue
        return value
    }
}
