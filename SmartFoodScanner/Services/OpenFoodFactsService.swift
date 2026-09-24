import Foundation

enum FoodScannerError: LocalizedError {
    case invalidBarcode
    case productNotFound
    case networkFailed

    var errorDescription: String? {
        switch self {
        case .invalidBarcode: "Enter a valid barcode."
        case .productNotFound: "Product not found in OpenFoodFacts."
        case .networkFailed: "Could not load product details."
        }
    }
}

struct OpenFoodFactsService {
    func fetchProduct(barcode: String) async throws -> Product {
        guard !barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=product_name,brands,ingredients_text,nutriments") else {
            throw FoodScannerError.invalidBarcode
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw FoodScannerError.networkFailed
        }

        let decoded = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
        guard decoded.status == 1, let item = decoded.product else {
            throw FoodScannerError.productNotFound
        }

        return Product(
            barcode: barcode,
            name: item.productName?.nilIfBlank ?? "Unknown product",
            brand: item.brands?.nilIfBlank ?? "Unknown brand",
            ingredientsText: item.ingredientsText?.nilIfBlank ?? "",
            nutrition: Nutrition(
                sugarPer100g: item.nutriments?.sugars100g,
                fatPer100g: item.nutriments?.fat100g,
                sodiumPer100g: item.nutriments?.sodium100g,
                fiberPer100g: item.nutriments?.fiber100g,
                proteinPer100g: item.nutriments?.proteins100g
            )
        )
    }
}

private struct OpenFoodFactsResponse: Decodable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

private struct OpenFoodFactsProduct: Decodable {
    let productName: String?
    let brands: String?
    let ingredientsText: String?
    let nutriments: OpenFoodFactsNutriments?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case ingredientsText = "ingredients_text"
        case nutriments
    }
}

private struct OpenFoodFactsNutriments: Decodable {
    let sugars100g: Double?
    let fat100g: Double?
    let sodium100g: Double?
    let fiber100g: Double?
    let proteins100g: Double?

    enum CodingKeys: String, CodingKey {
        case sugars100g = "sugars_100g"
        case fat100g = "fat_100g"
        case sodium100g = "sodium_100g"
        case fiber100g = "fiber_100g"
        case proteins100g = "proteins_100g"
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
