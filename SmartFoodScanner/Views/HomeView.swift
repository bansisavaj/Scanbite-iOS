import StoreKit
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var history: HistoryViewModel
    @Environment(\.requestReview) private var requestReview
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text("Smart Food Scanner")
                        .font(.largeTitle.weight(.semibold))
                        .multilineTextAlignment(.center)

                    Text("Understand packaged food in seconds.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                NavigationLink {
                    ScannerView()
                } label: {
                    Label("Scan Product", systemImage: "barcode.viewfinder")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .simultaneousGesture(TapGesture().onEnded {
                    AppAnalyticsService.shared.log(.barcodeScannerOpened)
                })

                NavigationLink {
                    IngredientsScannerView()
                } label: {
                    Label("Scan Ingredients", systemImage: "text.viewfinder")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .simultaneousGesture(TapGesture().onEnded {
                    AppAnalyticsService.shared.log(.ingredientsScannerOpened)
                })

                NavigationLink {
                    FoodChatView()
                } label: {
                    Label("Ask Food AI", systemImage: "message")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .simultaneousGesture(TapGesture().onEnded {
                    AppAnalyticsService.shared.log(.foodChatOpened)
                })

                Button("Search Product") {
                    AppAnalyticsService.shared.log(.manualSearchOpened)
                    viewModel.showManualSearch = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                if !history.recentProducts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent scans")
                                .font(.headline)

                            Spacer()

                            if history.recentProducts.count > 3 {
                                NavigationLink("Show more") {
                                    HistoryView()
                                }
                                .font(.subheadline.weight(.semibold))
                            }
                        }

                        ForEach(Array(history.recentProducts.prefix(3))) { product in
                            NavigationLink {
                                ProductResultView(barcode: product.barcode, preloadedProduct: product)
                            } label: {
                                RecentProductCard(product: product)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 12)
                }
            }
            .padding(24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AppAnalyticsService.shared.log(.homeViewed)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    EducationView()
                } label: {
                    Image(systemName: "book")
                }
                .accessibilityLabel("Food checklist")

                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $viewModel.showManualSearch) {
            NavigationStack {
                ManualSearchView(barcode: $viewModel.manualBarcode)
            }
        }
    }
}

private struct RecentProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(product.brand)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

private struct ManualSearchView: View {
    @Binding var barcode: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            TextField("Barcode", text: $barcode)
                .keyboardType(.numberPad)

            NavigationLink("Search") {
                ProductResultView(barcode: barcode)
            }
            .disabled(barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .navigationTitle("Search Product")
        .toolbar {
            Button("Done") { dismiss() }
        }
    }
}
