import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var recentProducts: [Product] = []

    func add(_ product: Product) {
        recentProducts.removeAll { $0.barcode == product.barcode }
        recentProducts.insert(product, at: 0)
        recentProducts = Array(recentProducts.prefix(50))
    }
}
