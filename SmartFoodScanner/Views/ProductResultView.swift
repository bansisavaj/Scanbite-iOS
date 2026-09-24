import StoreKit
import SwiftUI

struct ProductResultView: View {
    @EnvironmentObject private var history: HistoryViewModel
    @Environment(\.requestReview) private var requestReview
    @StateObject private var viewModel = ProductViewModel()
    @AppStorage(DietPreferenceStore.storageKey) private var dietPreferenceRaw = DietPreference.none.rawValue

    let barcode: String
    var preloadedProduct: Product?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let product = viewModel.product,
                   let summary = viewModel.healthSummary {
                    header(product)
                    dietBadge(summary.dietType)
                    dietConflictWarning(summary.dietType)
                    scoreCard(summary)
                    if !summary.isLikelyFood {
                        nonFoodCard()
                    }
                    highlightsCard(summary)
                    suggestionCard(summary.suggestion)
                    trustNoteCard(summary.trustNote)
                    AdBannerSlot()
                } else if viewModel.isLoading {
                    SkeletonResultView()
                } else {
                    ContentUnavailableView(
                        "No result",
                        systemImage: "barcode.viewfinder",
                        description: Text(viewModel.errorMessage ?? "Try scanning the barcode again.")
                    )
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Product")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showManualEntry) {
            ManualEstimateView(barcode: barcode) { name, sugar, protein, ultraProcessed in
                viewModel.applyManualProduct(
                    name: name,
                    sugar: sugar,
                    protein: protein,
                    ultraProcessed: ultraProcessed,
                    barcode: barcode
                )
            }
        }
        .task {
            if let preloadedProduct {
                viewModel.apply(preloadedProduct)
            } else {
                await viewModel.load(barcode: barcode)
            }

            if let product = viewModel.product {
                history.add(product)

                if preloadedProduct == nil {
                    // Never show a review prompt and an interstitial on the same
                    // scan — whichever would fire, only one system prompt wins.
                    if AppReviewService.registerSuccessfulScan(identifier: "barcode:\(product.barcode)") {
                        try? await Task.sleep(nanoseconds: 900_000_000)
                        requestReview()
                    } else {
                        InterstitialAdManager.shared.registerScanCompleted()
                    }
                }
            }
        }
    }

    private func header(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(product.name)
                .font(.largeTitle.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(product.brand)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func dietBadge(_ dietType: DietTypeResult) -> some View {
        Label(dietType.type.rawValue, systemImage: dietIcon(for: dietType.type))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(dietColor(for: dietType.type))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(dietColor(for: dietType.type).opacity(0.12), in: Capsule())
            .accessibilityLabel("Diet type: \(dietType.type.rawValue). \(dietType.explanation)")
    }

    private func dietIcon(for type: DietType) -> String {
        switch type {
        case .vegan: "leaf.fill"
        case .vegetarian: "carrot.fill"
        case .nonVegetarian: "fork.knife"
        case .uncertain: "questionmark.circle.fill"
        }
    }

    private func dietColor(for type: DietType) -> Color {
        switch type {
        case .vegan: .green
        case .vegetarian: .mint
        case .nonVegetarian: .orange
        case .uncertain: .secondary
        }
    }

    private func dietConflictWarning(_ dietType: DietTypeResult) -> some View {
        let preference = DietPreference(rawValue: dietPreferenceRaw) ?? .none
        guard preference.conflicts(with: dietType.type) else { return AnyView(EmptyView()) }

        return AnyView(
            Label(
                "This doesn't match your \(preference.rawValue.lowercased()) preference — \(dietType.explanation.lowercased())",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.red)
            .cardStyle()
        )
    }

    private func scoreCard(_ summary: HealthSummary) -> some View {
        VStack(spacing: 14) {
            Text(summary.rating.rawValue)
                .font(.system(size: 88, weight: .bold, design: .rounded))
                .foregroundStyle(color(for: summary.rating))
                .frame(width: 132, height: 132)
                .background(color(for: summary.rating).opacity(0.12), in: Circle())

            Text(summary.verdict)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }

    private func highlightsCard(_ summary: HealthSummary) -> some View {
        HStack(spacing: 10) {
            ForEach(summary.highlights) { highlight in
                VStack(spacing: 8) {
                    Text(highlight.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(highlight.value)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, minHeight: 76)
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .cardStyle()
    }

    private func suggestionCard(_ suggestion: String) -> some View {
        Label(suggestion, systemImage: "lightbulb")
            .font(.headline)
            .cardStyle()
    }

    private func nonFoodCard() -> some View {
        Label("This scan may not be an edible food product. Please confirm the package before using this result.", systemImage: "exclamationmark.triangle")
            .font(.headline)
            .foregroundStyle(.orange)
            .cardStyle()
    }

    private func trustNoteCard(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("On-device AI insight", systemImage: "sparkles")
                .font(.headline)
            Text(note)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
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

private struct SkeletonResultView: View {
    var body: some View {
        VStack(spacing: 18) {
            RoundedRectangle(cornerRadius: 16)
                .fill(.gray.opacity(0.18))
                .frame(height: 88)
            RoundedRectangle(cornerRadius: 18)
                .fill(.gray.opacity(0.18))
                .frame(height: 220)
            RoundedRectangle(cornerRadius: 16)
                .fill(.gray.opacity(0.18))
                .frame(height: 108)
        }
        .redacted(reason: .placeholder)
    }
}

private struct ManualEstimateView: View {
    let barcode: String
    let onSave: (String, Double?, Double?, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var sugar = ""
    @State private var protein = ""
    @State private var ultraProcessed = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Product name", text: $name)
                TextField("Sugar per 100 g", text: $sugar)
                    .keyboardType(.decimalPad)
                TextField("Protein per 100 g", text: $protein)
                    .keyboardType(.decimalPad)
                Toggle("Looks ultra-processed", isOn: $ultraProcessed)
            }
            .navigationTitle("Manual Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Show Score") {
                        onSave(name, Double(sugar), Double(protein), ultraProcessed)
                        dismiss()
                    }
                }
            }
        }
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}
