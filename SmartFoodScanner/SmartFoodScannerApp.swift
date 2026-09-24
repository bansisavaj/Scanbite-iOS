import AppTrackingTransparency
import FirebaseCore
import GoogleMobileAds
import SwiftUI

@main
struct SmartFoodScannerApp: App {
    @StateObject private var historyViewModel = HistoryViewModel()
    private let locationService = LocationService(notificationService: NotificationService())

    init() {
        FirebaseApp.configure()
        AppFirebaseRuntime.configureCollections()
        AppRemoteConfigService.shared.configure()
        AppAnalyticsService.shared.log(.appLaunch)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyViewModel)
                .task {
                    // Ask for tracking permission before ads ever load — the
                    // SDK only starts serving personalized ads once this
                    // resolves, and Apple rejects apps that ship the usage
                    // string in Info.plist without ever presenting this.
                    await requestTrackingAuthorizationIfNeeded()

                    MobileAds.shared.start { status in
                        print("[Ads] MobileAds SDK started. Adapter statuses: \(status.adapterStatusesByClassName)")
                    }

                    Task {
                        await AppRemoteConfigService.shared.fetchAndActivate()
                        InterstitialAdManager.shared.preload()
                    }
                    await locationService.startShoppingAwareness()
                }
        }
    }

    /// Presents the system ATT prompt once per install. A brief delay lets
    /// the home screen render first, which Apple recommends over prompting
    /// before any UI is visible.
    private func requestTrackingAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

        try? await Task.sleep(nanoseconds: 500_000_000)

        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { status in
                AppAnalyticsService.shared.log(
                    .attAuthorizationResolved,
                    parameters: ["status": status.rawValue]
                )
                continuation.resume()
            }
        }
    }
}
