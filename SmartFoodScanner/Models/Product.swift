import Foundation

struct Product: Identifiable, Codable, Hashable {
    var id: String { barcode }
    let barcode: String
    let name: String
    let brand: String
    let ingredientsText: String
    let nutrition: Nutrition

    static let sample = Product(
        barcode: "sample",
        name: "Crunchy Oat Bar",
        brand: "Everyday Pantry",
        ingredientsText: "Oats, sugar, sunflower oil, whey powder, salt, natural flavour.",
        nutrition: Nutrition(
            sugarPer100g: 28,
            fatPer100g: 11,
            sodiumPer100g: 0.34,
            fiberPer100g: 5,
            proteinPer100g: 7
        )
    )
}
