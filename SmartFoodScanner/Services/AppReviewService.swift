import Foundation

struct AppReviewService {
    private static let promptThreshold = 3

    static func registerSuccessfulScan(identifier: String) -> Bool {
        let defaults = UserDefaults.standard
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let promptKey = "review_prompt_requested_\(version)"
        let identifiersKey = "review_scan_identifiers_\(version)"

        guard defaults.bool(forKey: promptKey) == false else { return false }

        var identifiers = defaults.stringArray(forKey: identifiersKey) ?? []
        guard identifiers.contains(identifier) == false else { return false }

        identifiers.append(identifier)
        defaults.set(Array(identifiers.suffix(promptThreshold)), forKey: identifiersKey)

        guard identifiers.count >= promptThreshold else { return false }

        defaults.set(true, forKey: promptKey)
        AppAnalyticsService.shared.log(.appReviewRequested)
        return true
    }
}
