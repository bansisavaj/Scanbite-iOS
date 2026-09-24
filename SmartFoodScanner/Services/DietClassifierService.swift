import Foundation

struct DietClassifierService {
    private let nonVegetarianMarkers = ["gelatin", "fish oil", "carmine"]
    private let vegetarianButNotVeganMarkers = ["rennet", "whey", "casein", "milk", "cheese", "butter", "cream"]

    func classify(ingredients: String) -> DietTypeResult {
        let normalized = ingredients.lowercased()
        let nonVegMatches = nonVegetarianMarkers.filter { normalized.contains($0) }
        if !nonVegMatches.isEmpty {
            return DietTypeResult(
                type: .nonVegetarian,
                explanation: "This product appears to include animal-derived ingredients.",
                matchedIngredients: nonVegMatches
            )
        }

        let vegetarianMatches = vegetarianButNotVeganMarkers.filter { normalized.contains($0) }
        if !vegetarianMatches.isEmpty {
            return DietTypeResult(
                type: .vegetarian,
                explanation: "This product appears suitable for vegetarians, but not vegans, based on the ingredients listed.",
                matchedIngredients: vegetarianMatches
            )
        }

        guard !ingredients.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return DietTypeResult(
                type: .uncertain,
                explanation: "There is not enough ingredient information to classify this confidently.",
                matchedIngredients: []
            )
        }

        return DietTypeResult(
            type: .vegan,
            explanation: "This product appears suitable for vegans based on the ingredients listed.",
            matchedIngredients: []
        )
    }
}
