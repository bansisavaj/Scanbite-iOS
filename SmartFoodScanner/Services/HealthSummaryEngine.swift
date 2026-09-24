import Foundation

struct HealthSummaryEngine {
    private let aiInsightService = OnDeviceAIInsightService()
    private let dietClassifier = DietClassifierService()

    func generateHealthSummary(product: FoodProduct) -> HealthSummary {
        let nutrition = product.nutrition
        let sugar = nutrition.sugarLevel
        let protein = proteinLabel(nutrition.proteinPer100g)
        let ultraProcessed = isUltraProcessed(product.ingredientsText)
        let isLikelyFood = isLikelyFood(product)

        var penalty = 0
        if !isLikelyFood { penalty += 4 }
        if sugar == .high { penalty += 2 }
        if sugar == .medium { penalty += 1 }
        if nutrition.sodiumLevel == .high { penalty += 1 }
        if nutrition.fatLevel == .high { penalty += 1 }
        if ultraProcessed { penalty += 1 }
        if nutrition.fiberLevel == .high { penalty -= 1 }
        if nutrition.proteinPer100g ?? 0 >= 8 { penalty -= 1 }

        let rating: HealthSummary.Rating
        switch penalty {
        case ...(-1): rating = .a
        case 0: rating = .b
        case 1...2: rating = .c
        case 3: rating = .d
        default: rating = .e
        }

        return HealthSummary(
            rating: rating,
            verdict: isLikelyFood ? verdict(for: rating, sugar: sugar, ultraProcessed: ultraProcessed) : "This may not be a food item",
            isLikelyFood: isLikelyFood,
            highlights: [
                .init(title: "Sugar", value: sugar.rawValue),
                .init(title: "Protein", value: protein),
                .init(title: "Ultra-processed", value: ultraProcessed ? "Yes" : "No")
            ],
            suggestion: isLikelyFood ? suggestion(for: rating, sugar: sugar, protein: protein) : "Scan a food label or ingredient list for a better result.",
            trustNote: aiInsightService.productInsight(
                product: product,
                sugar: sugar,
                protein: protein,
                ultraProcessed: ultraProcessed,
                isLikelyFood: isLikelyFood
            ),
            dietType: dietClassifier.classify(ingredients: product.ingredientsText)
        )
    }

    private func proteinLabel(_ protein: Double?) -> String {
        guard let protein else { return "Low" }
        if protein >= 15 { return "High" }
        if protein >= 6 { return "Good" }
        return "Low"
    }

    private func isUltraProcessed(_ ingredients: String) -> Bool {
        let markers = [
            "maltodextrin", "emulsifier", "stabilizer", "colour", "color",
            "flavour", "flavor", "modified starch", "hydrogenated", "preservative"
        ]
        let normalized = ingredients.lowercased()
        return markers.contains { normalized.contains($0) } || ingredients.split(separator: ",").count >= 12
    }

    private func isLikelyFood(_ product: FoodProduct) -> Bool {
        let text = "\(product.name) \(product.brand) \(product.ingredientsText)".lowercased()
        let foodSignals = [
            "ingredient", "nutrition", "sugar", "salt", "flour", "maida", "milk",
            "oil", "cocoa", "oat", "rice", "wheat", "protein", "fiber", "fibre",
            "snack", "drink", "juice", "bread", "chocolate", "cookie", "biscuit"
        ]
        let nonFoodSignals = [
            "detergent", "soap", "shampoo", "conditioner", "battery", "charger",
            "cosmetic", "lotion", "cream for external use", "medicine", "tablet",
            "capsule", "cleaner", "disinfectant", "toothpaste", "deodorant",
            "warning", "flammable", "keep out of reach"
        ]

        if nonFoodSignals.contains(where: { text.contains($0) }) {
            return false
        }

        let hasNutrition = product.nutrition.sugarPer100g != nil ||
        product.nutrition.fatPer100g != nil ||
        product.nutrition.sodiumPer100g != nil ||
        product.nutrition.fiberPer100g != nil ||
        product.nutrition.proteinPer100g != nil

        return hasNutrition || foodSignals.contains(where: { text.contains($0) })
    }

    private func verdict(for rating: HealthSummary.Rating, sugar: Nutrition.Level, ultraProcessed: Bool) -> String {
        if sugar == .high { return "Okay, but high sugar" }
        if ultraProcessed && rating.rawValue >= "C" { return "Good for occasional use" }

        switch rating {
        case .a: return "Good choice"
        case .b: return "Looks reasonable"
        case .c: return "Okay in moderation"
        case .d: return "Not healthy for daily use"
        case .e: return "Best as an occasional treat"
        }
    }

    private func suggestion(for rating: HealthSummary.Rating, sugar: Nutrition.Level, protein: String) -> String {
        if sugar == .high { return "Try a lower sugar alternative." }
        if protein == "Low" { return "Pair it with a protein-rich food." }

        switch rating {
        case .a, .b: return "Good for a simple everyday choice."
        case .c: return "Good for occasional use."
        case .d, .e: return "Compare with a less processed option."
        }
    }

}
