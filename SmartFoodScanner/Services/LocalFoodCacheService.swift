import Foundation

struct LocalFoodCacheService {
    private let key = "cached-food-products-v1"

    func product(for barcode: String) -> FoodProduct? {
        allProducts()[barcode]
    }

    func save(_ product: FoodProduct) {
        var products = allProducts()
        products[product.barcode] = product
        guard let data = try? JSONEncoder().encode(products) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func allProducts() -> [String: FoodProduct] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let products = try? JSONDecoder().decode([String: FoodProduct].self, from: data) else {
            return [:]
        }
        return products
    }
}
