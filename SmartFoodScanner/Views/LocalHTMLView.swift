import SwiftUI
import WebKit

/// Displays one of the bundled LegalDocs HTML files (privacy.html,
/// terms.html, support.html) in an in-app web view. No network request is
/// made — these load straight from the app bundle, so they work offline
/// and never depend on an external host being up.
struct LocalHTMLView: UIViewRepresentable {
    let fileName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "html", subdirectory: "LegalDocs") else {
            return
        }
        // Load with access to the whole LegalDocs folder so the shared
        // style.css resolves correctly.
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}

struct LegalWebPageView: View {
    let title: String
    let fileName: String

    var body: some View {
        LocalHTMLView(fileName: fileName)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
    }
}
