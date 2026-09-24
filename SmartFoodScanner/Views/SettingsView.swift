import SwiftUI

struct SettingsView: View {
    @AppStorage(DietPreferenceStore.storageKey) private var dietPreferenceRaw = DietPreference.none.rawValue

    var body: some View {
        List {
            Section {
                Picker("Diet Preference", selection: $dietPreferenceRaw) {
                    ForEach(DietPreference.allCases) { preference in
                        Text(preference.rawValue).tag(preference.rawValue)
                    }
                }
            } header: {
                Text("Diet")
            } footer: {
                Text("We'll flag scanned products that don't match your preference, based on ingredient text.")
            }

            Section {
                NavigationLink {
                    LegalWebPageView(title: "Terms & Conditions", fileName: "terms")
                        .onAppear { AppAnalyticsService.shared.log(.termsViewed) }
                } label: {
                    SettingsRow(title: "Terms & Conditions", systemImage: "doc.text")
                }

                NavigationLink {
                    LegalWebPageView(title: "Privacy Policy", fileName: "privacy")
                        .onAppear { AppAnalyticsService.shared.log(.privacyViewed) }
                } label: {
                    SettingsRow(title: "Privacy Policy", systemImage: "hand.raised")
                }

                NavigationLink {
                    LegalWebPageView(title: "Support", fileName: "support")
                        .onAppear { AppAnalyticsService.shared.log(.supportViewed) }
                } label: {
                    SettingsRow(title: "Support", systemImage: "questionmark.circle")
                }
            }

            Section {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Build", value: appBuild)
            } header: {
                Text("About")
            } footer: {
                Text("Food insights are label-based guidance and are not medical advice.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            AppAnalyticsService.shared.log(.settingsViewed)
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

private struct SettingsRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .foregroundStyle(.primary)
    }
}

// Terms & Conditions, Privacy Policy, and Support content now lives in
// LegalDocs/terms.html, LegalDocs/privacy.html, and LegalDocs/support.html
// (bundled and rendered via LocalHTMLView), so it stays in sync with the
// copies hosted for App Store Connect's Privacy Policy / Support URLs.
