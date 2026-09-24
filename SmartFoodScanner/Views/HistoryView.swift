import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var history: HistoryViewModel

    var body: some View {
        Group {
            if history.recentProducts.isEmpty {
                ContentUnavailableView(
                    "No scans yet",
                    systemImage: "clock",
                    description: Text("Scanned products will appear here.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(history.recentProducts) { product in
                            NavigationLink {
                                ProductResultView(barcode: product.barcode, preloadedProduct: product)
                            } label: {
                                HistoryProductCard(product: product)
                            }
                            .buttonStyle(.plain)
                        }

                        AdBannerSlot()
                            .padding(.top, 4)
                    }
                    .padding(20)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            AppAnalyticsService.shared.log(.historyViewed)
        }
    }
}

private struct HistoryProductCard: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "barcode.viewfinder")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 42, height: 42)
                .background(Color(.secondarySystemGroupedBackground), in: Circle())

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

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}
