import GoogleMobileAds
import SwiftUI

/// Central place for ad unit IDs, frequency rules, and interstitial lifecycle.
/// Ad unit IDs are test IDs (Google's public sample units) — swap for real
/// AdMob unit IDs before release, and drive them from Remote Config so they
/// can be changed without a resubmit.
enum AdConfig {
    static var bannerUnitID: String {
        AppRemoteConfigService.shared.bannerAdUnitID
    }

    static var interstitialUnitID: String {
        AppRemoteConfigService.shared.interstitialAdUnitID
    }

    static var adsEnabled: Bool {
        AppRemoteConfigService.shared.areAdsEnabled
    }

    /// Show an interstitial after every Nth completed scan.
    static var interstitialFrequency: Int {
        max(AppRemoteConfigService.shared.interstitialScanFrequency, 1)
    }
}

@MainActor
final class InterstitialAdManager: NSObject, ObservableObject {
    static let shared = InterstitialAdManager()

    private var interstitial: InterstitialAd?
    private var scanCountSinceLastAd = 0

    private override init() {
        super.init()
    }

    func preload() {
        guard AdConfig.adsEnabled, AdConfig.interstitialUnitID.isEmpty == false else { return }
        Task {
            do {
                interstitial = try await InterstitialAd.load(
                    with: AdConfig.interstitialUnitID,
                    request: Request()
                )
                interstitial?.fullScreenContentDelegate = self
            } catch {
                AppAnalyticsService.shared.record(error, context: "interstitial_load")
            }
        }
    }

    /// Call once per completed product scan. Shows an interstitial every
    /// `interstitialFrequency` scans, never on the very first scan of a
    /// session so the user sees value before hitting an ad.
    func registerScanCompleted() {
        guard AdConfig.adsEnabled else { return }
        scanCountSinceLastAd += 1

        guard scanCountSinceLastAd >= AdConfig.interstitialFrequency else { return }

        guard let interstitial,
              let root = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                .first?.rootViewController
        else {
            preload()
            return
        }

        interstitial.present(from: root)
        scanCountSinceLastAd = 0
    }
}

extension InterstitialAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitial = nil
        preload()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        AppAnalyticsService.shared.record(error, context: "interstitial_present")
        interstitial = nil
        preload()
    }
}

/// SwiftUI wrapper around `BannerView`. Sizes itself to the standard
/// adaptive anchored banner for the current width.
struct BannerAdView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> BannerViewController {
        BannerViewController()
    }

    func updateUIViewController(_ uiViewController: BannerViewController, context: Context) {}
}

final class BannerViewController: UIViewController {
    private let bannerView = BannerView()
    private var hasRequestedAd = false

    override func viewDidLoad() {
        super.viewDidLoad()
        guard AdConfig.adsEnabled else {
            print("[Ads] Banner skipped — ads_enabled is false in Remote Config")
            return
        }

        bannerView.adUnitID = AdConfig.bannerUnitID
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)

        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerView.topAnchor.constraint(equalTo: view.topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard AdConfig.adsEnabled,
              hasRequestedAd == false,
              view.frame.width > 0,
              AdConfig.bannerUnitID.isEmpty == false
        else { return }

        hasRequestedAd = true
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: view.frame.width)
        print("[Ads] Requesting banner, unit=\(AdConfig.bannerUnitID), width=\(view.frame.width)")
        bannerView.load(Request())
    }
}

extension BannerViewController: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("[Ads] Banner loaded successfully")
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("[Ads] Banner FAILED to load: \(error.localizedDescription)")
        hasRequestedAd = false
    }
}

/// Drop-in row that only takes up space when ads are enabled, so layouts
/// don't leave a gap when a Remote Config kill switch turns ads off.
struct AdBannerSlot: View {
    var body: some View {
        if AdConfig.adsEnabled {
            BannerAdView()
                .frame(height: 50)
        }
    }
}
