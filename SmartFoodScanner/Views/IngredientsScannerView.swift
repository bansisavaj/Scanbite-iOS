import StoreKit
import SwiftUI

struct IngredientsScannerView: View {
    @Environment(\.requestReview) private var requestReview
    @StateObject private var viewModel = IngredientsScannerViewModel()
    @State private var hasRegisteredCurrentResult = false

    var body: some View {
        ZStack {
            if let analysis = viewModel.analysis {
                IngredientAnalysisResultView(analysis: analysis) {
                    viewModel.retry()
                }
            } else {
                IngredientCameraView { image in
                    Task {
                        await viewModel.process(image: image)
                    }
                }
                .ignoresSafeArea()

                scannerOverlay

                if viewModel.isProcessing {
                    ProgressView("Reading ingredients")
                        .padding(18)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }

                if let prompt = viewModel.prompt {
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Text(prompt)
                                .font(.headline)
                            Text("Keep the ingredients clear and inside the box.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button("Try Again") {
                                viewModel.retry()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(18)
                        .background(.background, in: RoundedRectangle(cornerRadius: 16))
                        .padding(20)
                    }
                }
            }
        }
        .navigationTitle("Scan Ingredients")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AppAnalyticsService.shared.log(.ingredientsScannerOpened)
        }
        .onChange(of: viewModel.analysis != nil) { _, hasAnalysis in
            guard hasAnalysis, hasRegisteredCurrentResult == false else {
                if hasAnalysis == false {
                    hasRegisteredCurrentResult = false
                }
                return
            }

            hasRegisteredCurrentResult = true
            let identifier = "ingredients:\(UUID().uuidString)"
            guard AppReviewService.registerSuccessfulScan(identifier: identifier) else { return }

            Task {
                try? await Task.sleep(nanoseconds: 900_000_000)
                requestReview()
            }
        }
    }

    private var scannerOverlay: some View {
        VStack(spacing: 18) {
            Spacer()

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white, lineWidth: 3)
                .frame(width: 310, height: 210)
                .shadow(color: .black.opacity(0.35), radius: 10)

            VStack(spacing: 8) {
                Label("Keep text inside box", systemImage: "text.viewfinder")
                Label("Ensure good lighting", systemImage: "sun.max")
                Label("Avoid blur", systemImage: "camera.metering.center.weighted")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(14)
            .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))

            Spacer()
                .frame(height: 96)
        }
        .allowsHitTesting(false)
    }
}

private struct IngredientAnalysisResultView: View {
    let analysis: IngredientAnalysis
    let onRetake: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 14) {
                    Text(analysis.rating.rawValue)
                        .font(.system(size: 88, weight: .bold, design: .rounded))
                        .foregroundStyle(color(for: analysis.rating))
                        .frame(width: 132, height: 132)
                        .background(color(for: analysis.rating).opacity(0.12), in: Circle())

                    Text(analysis.verdict)
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)

                VStack(spacing: 10) {
                    if !analysis.isLikelyFood {
                        badgeRow(
                            title: "Not food?",
                            value: "This scan may not be an edible product. Please confirm the package label.",
                            systemImage: "exclamationmark.triangle",
                            isPositive: false
                        )
                    }
                    badgeRow(
                        title: "Diet",
                        value: analysis.dietType.rawValue,
                        systemImage: "leaf",
                        isPositive: analysis.dietType != .nonVegetarian
                    )
                    badgeRow(
                        title: "Kids",
                        value: analysis.kidsFriendly.reason,
                        systemImage: "figure.and.child.holdinghands",
                        isPositive: analysis.kidsFriendly.isSafe
                    )
                    badgeRow(
                        title: "Elder",
                        value: analysis.elderSafe.reason,
                        systemImage: "heart",
                        isPositive: analysis.elderSafe.isSafe
                    )
                }

                HStack(spacing: 10) {
                    ForEach(analysis.highlights) { highlight in
                        VStack(spacing: 8) {
                            Text(highlight.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(highlight.value)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, minHeight: 76)
                        .padding(10)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .cardStyle()

                Label(analysis.suggestion, systemImage: "lightbulb")
                    .font(.headline)
                    .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    Label("On-device AI insight", systemImage: "sparkles")
                        .font(.headline)
                    Text(analysis.trustNote)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .cardStyle()

                Button("Retake Photo", action: onRetake)
                    .buttonStyle(.bordered)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func badgeRow(title: String, value: String, systemImage: String, isPositive: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .foregroundStyle(isPositive ? .green : .orange)
        .background((isPositive ? Color.green : Color.orange).opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    private func color(for rating: HealthSummary.Rating) -> Color {
        switch rating {
        case .a: .green
        case .b: .mint
        case .c: .yellow
        case .d: .orange
        case .e: .red
        }
    }
}
