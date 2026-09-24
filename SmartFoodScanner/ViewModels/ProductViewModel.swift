import Foundation

@MainActor
final class ProductViewModel: ObservableObject {
    @Published private(set) var product: Product?
    @Published private(set) var healthSummary: HealthSummary?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var showManualEntry = false

    private let foodService = FoodDataService()
    private let summaryEngine = HealthSummaryEngine()

    func load(barcode: String) async {
        isLoading = true
        errorMessage = nil

        if let product = await foodService.fetchFood(barcode: barcode) {
            apply(product)
        } else {
            errorMessage = "We could not find this product yet."
            showManualEntry = true
        }

        isLoading = false
    }

    func apply(_ product: Product) {
        self.product = product
        let summary = summaryEngine.generateHealthSummary(product: product)
        healthSummary = summary
        AppAnalyticsService.shared.log(
            .productResultViewed,
            parameters: [
                "rating": summary.rating.rawValue,
                "likely_food": summary.isLikelyFood
            ]
        )
    }

    func applyManualProduct(name: String, sugar: Double?, protein: Double?, ultraProcessed: Bool, barcode: String) {
        let ingredients = ultraProcessed ? "manual entry, flavour, emulsifier, preservative" : "manual entry"
        let product = Product(
            barcode: barcode,
            name: name.isEmpty ? "Manual product" : name,
            brand: "Manual estimate",
            ingredientsText: ingredients,
            nutrition: Nutrition(
                sugarPer100g: sugar,
                fatPer100g: nil,
                sodiumPer100g: nil,
                fiberPer100g: nil,
                proteinPer100g: protein
            )
        )
        apply(product)
        foodService.save(product)
        showManualEntry = false
    }
}
