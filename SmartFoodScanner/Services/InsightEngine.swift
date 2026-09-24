import Foundation

struct InsightEngine {
    func generate(for product: Product, diet: DietTypeResult) -> InsightResult {
        let nutrition = product.nutrition
        var good: [String] = []
        var concerns: [String] = []
        var reasons: [String] = []
        var longTerm: [String] = []

        if nutrition.fiberLevel == .high || nutrition.fiberLevel == .medium {
            good.append("Contains a useful amount of fiber.")
        }
        if let protein = nutrition.proteinPer100g, protein >= 6 {
            good.append("Includes some protein for fullness.")
        }
        if product.ingredientsText.split(separator: ",").count <= 5, !product.ingredientsText.isEmpty {
            good.append("Has a relatively short ingredient list.")
        }
        if good.isEmpty {
            good.append("The label is readable enough to review quickly.")
        }

        switch nutrition.sugarLevel {
        case .high:
            concerns.append("Sugar is on the higher side.")
            reasons.append("Sugar was mentioned because it is high for a 100 g serving.")
            longTerm.append("Regularly choosing high-sugar foods may contribute to weight gain over time.")
        case .medium:
            concerns.append("Sugar is moderate, so portion size matters.")
            reasons.append("Sugar was noted because it sits in the middle range.")
        default:
            break
        }

        switch nutrition.sodiumLevel {
        case .high:
            concerns.append("Sodium is high for frequent eating.")
            reasons.append("Sodium was flagged because it is above the high threshold.")
            longTerm.append("Frequent high-sodium choices can contribute to higher salt intake across the day.")
        case .medium:
            concerns.append("Sodium is moderate.")
            reasons.append("Sodium was included because it is not low.")
        default:
            break
        }

        if nutrition.fatLevel == .high {
            concerns.append("Fat is high compared with many packaged foods.")
            reasons.append("Fat was included because the product has a high fat level per 100 g.")
        }

        let quickInsight = quickInsight(for: nutrition, productName: product.name)
        let suitability = suitability(for: nutrition)

        return InsightResult(
            quickInsight: quickInsight,
            goodPoints: Array(good.prefix(4)),
            concerns: Array(concerns.prefix(4)),
            longTermInsight: longTerm.first ?? "For everyday choices, it can help to compare similar products and pick the one that fits your routine.",
            suitability: suitability,
            nutritionSnapshot: [
                ("Sugar", nutrition.sugarLevel),
                ("Fat", nutrition.fatLevel),
                ("Sodium", nutrition.sodiumLevel),
                ("Fiber", nutrition.fiberLevel)
            ],
            reasons: reasons + ["Diet guidance: \(diet.explanation)"]
        )
    }

    private func quickInsight(for nutrition: Nutrition, productName: String) -> String {
        if nutrition.sugarLevel == .high && nutrition.sodiumLevel == .high {
            return "This product is easy to enjoy, but both sugar and sodium are high, so it is better as an occasional choice."
        }
        if nutrition.sugarLevel == .high {
            return "This product gives quick energy but contains a relatively high amount of sugar, so it is better as an occasional snack."
        }
        if nutrition.sodiumLevel == .high {
            return "This product is convenient, but the sodium is high, so it may suit occasional use more than daily eating."
        }
        if nutrition.fiberLevel == .high {
            return "This product has a helpful amount of fiber and looks reasonable to compare with similar options."
        }
        return "This product looks straightforward. Check the notes below to see if it fits what you need today."
    }

    private func suitability(for nutrition: Nutrition) -> [String] {
        [
            nutrition.sugarLevel == .high ? "Kids: occasional only." : "Kids: reasonable in normal portions.",
            "Adults: moderate use is a sensible starting point.",
            nutrition.sodiumLevel == .high ? "Elderly: consider lower-sodium alternatives if needed." : "Elderly: compare with personal dietary needs.",
            nutrition.proteinPer100g ?? 0 >= 6 ? "Fitness: includes some protein." : "Fitness: depends on your sugar and protein goals."
        ]
    }
}
