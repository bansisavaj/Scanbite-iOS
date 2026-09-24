import Foundation

struct FoodDataService {
    private let openFoodFacts = OpenFoodFactsService()
    private let cache = LocalFoodCacheService()

    func fetchFood(barcode: String) async -> FoodProduct? {
        if let cached = cache.product(for: barcode) {
            return cached
        }

        if let product = await fetchFromOpenFoodFactsTryingVariants(barcode: barcode) {
            if product.hasUsableNutrition {
                save(product)
                return product
            } else if let enriched = await fetchFromUSDA(query: product.name, barcode: barcode, fallback: product) {
                save(enriched)
                return enriched
            }
            save(product)
            return product
        }

        // OpenFoodFacts has no record at all for this barcode (or any of
        // its normalized variants). USDA's search also matches on GTIN/UPC,
        // so try the raw barcode itself as the query before giving up.
        if let usdaOnly = await fetchFromUSDA(query: barcode, barcode: barcode) {
            save(usdaOnly)
            return usdaOnly
        }

        if let local = fallbackLocalSearch(barcode: barcode) {
            return local
        }

        return nil
    }

    /// Tries the scanned barcode as-is first, then normalized variants
    /// (e.g. UPC-E expanded to UPC-A) — a raw UPC-E scan from a small
    /// package otherwise never matches OpenFoodFacts' indexing.
    private func fetchFromOpenFoodFactsTryingVariants(barcode: String) async -> FoodProduct? {
        for candidate in BarcodeNormalizer.candidates(for: barcode) {
            if let product = try? await fetchFromOpenFoodFacts(barcode: candidate) {
                // Keep the cache keyed on what was actually scanned, not
                // the normalized variant that happened to match, so a
                // repeat scan of the same item hits the cache.
                return Product(
                    barcode: barcode,
                    name: product.name,
                    brand: product.brand,
                    ingredientsText: product.ingredientsText,
                    nutrition: product.nutrition
                )
            }
        }
        return nil
    }

    func save(_ product: FoodProduct) {
        cache.save(product)
    }

    func fetchFromOpenFoodFacts(barcode: String) async throws -> FoodProduct {
        try await openFoodFacts.fetchProduct(barcode: barcode)
    }

    func fetchFromUSDA(query: String, barcode: String, fallback: FoodProduct? = nil) async -> FoodProduct? {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let apiKey = AppRemoteConfigService.shared.usdaAPIKey
        guard apiKey.isEmpty == false else { return nil }

        AppAnalyticsService.shared.log(.usdaLookupAttempted)

        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: "1")
        ]

        guard let url = components?.url,
              let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode(USDAFoodSearchResponse.self, from: data),
              let food = decoded.foods.first else {
            AppAnalyticsService.shared.log(.usdaLookupFailed)
            return nil
        }

        AppAnalyticsService.shared.log(.usdaLookupSucceeded)

        return Product(
            barcode: barcode,
            name: fallback?.name ?? food.description.capitalized,
            brand: fallback?.brand ?? "USDA FoodData Central",
            ingredientsText: fallback?.ingredientsText ?? food.ingredients ?? "",
            nutrition: Nutrition(
                sugarPer100g: food.value(for: "Sugars, total including NLEA"),
                fatPer100g: food.value(for: "Total lipid (fat)"),
                sodiumPer100g: food.value(for: "Sodium, Na").map { $0 / 1000 },
                fiberPer100g: food.value(for: "Fiber, total dietary"),
                proteinPer100g: food.value(for: "Protein")
            )
        )
    }

    func fallbackLocalSearch(barcode: String) -> FoodProduct? {
        cache.product(for: barcode)
    }
}

private extension Product {
    var hasUsableNutrition: Bool {
        nutrition.sugarPer100g != nil ||
        nutrition.fatPer100g != nil ||
        nutrition.sodiumPer100g != nil ||
        nutrition.fiberPer100g != nil ||
        nutrition.proteinPer100g != nil
    }
}

private struct USDAFoodSearchResponse: Decodable {
    let foods: [USDAFood]
}

private struct USDAFood: Decodable {
    let description: String
    let ingredients: String?
    let foodNutrients: [USDANutrient]

    func value(for nutrientName: String) -> Double? {
        foodNutrients.first { $0.nutrientName == nutrientName }?.value
    }
}

private struct USDANutrient: Decodable {
    let nutrientName: String
    let value: Double?
}
