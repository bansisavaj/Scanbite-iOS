import Foundation

struct IngredientAnalysisEngine {
    private let aiInsightService = OnDeviceAIInsightService()

    private let sugarMarkers = [
        "sugar", "glucose", "fructose", "syrup", "dextrose", "maltose",
        "sucrose", "corn syrup", "honey", "molasses", "fruit juice concentrate"
    ]
    private let additiveMarkers = [
        "msg", "monosodium glutamate", "preservative", "emulsifier",
        "stabilizer", "artificial color", "artificial colour", "flavour", "flavor"
    ]
    private let allergenMarkers = [
        "milk", "wheat", "soy", "peanut", "tree nut", "almond", "cashew",
        "egg", "fish", "shellfish", "sesame", "gluten"
    ]
    private let nonVegMarkers = ["gelatin", "fish oil", "chicken", "beef", "pork", "fish", "shellfish", "carmine"]
    private let vegetarianMarkers = ["milk", "whey", "casein", "cheese", "butter", "cream", "rennet", "egg"]

    func analyzeIngredients(text: String) -> IngredientAnalysis {
        let normalized = text.lowercased()
        let sugarHits = matches(in: normalized, markers: sugarMarkers)
        let additiveHits = matches(in: normalized, markers: additiveMarkers) + eNumberMatches(in: normalized)
        let allergenHits = matches(in: normalized, markers: allergenMarkers)
        let diet = classifyDiet(normalized)
        let isLikelyFood = isLikelyFood(normalized)

        var penalty = 0
        if !isLikelyFood { penalty += 4 }
        if sugarHits.count >= 3 { penalty += 2 }
        if sugarHits.count == 1 || sugarHits.count == 2 { penalty += 1 }
        if !additiveHits.isEmpty { penalty += 1 }
        if additiveHits.count >= 3 { penalty += 1 }
        if diet == .nonVegetarian { penalty += 1 }
        if normalized.split(separator: ",").count >= 12 { penalty += 1 }

        let rating: HealthSummary.Rating
        switch penalty {
        case ...0: rating = .a
        case 1: rating = .b
        case 2: rating = .c
        case 3: rating = .d
        default: rating = .e
        }

        let sugarLevel = sugarHits.count >= 3 ? "High" : sugarHits.isEmpty ? "Low" : "Medium"
        let risk = riskLevel(for: rating)
        let kidsSafe = sugarLevel != "High" && additiveHits.count < 3
        let elderSafe = !normalized.contains("sodium") && !normalized.contains("salt") && additiveHits.count < 4

        return IngredientAnalysis(
            rating: rating,
            verdict: isLikelyFood ? verdict(for: rating, sugarLevel: sugarLevel, additives: additiveHits) : "This may not be a food item",
            isLikelyFood: isLikelyFood,
            dietType: diet,
            kidsFriendly: .init(
                isSafe: kidsSafe,
                reason: kidsSafe ? "Kids friendly" : "Not kids friendly: high sugar or many additives"
            ),
            elderSafe: .init(
                isSafe: elderSafe,
                reason: elderSafe ? "Elder safe" : "Not elder safe: salt or additives need attention"
            ),
            highlights: [
                .init(title: "Sugar", value: sugarLevel),
                .init(title: "Additives", value: additiveHits.isEmpty ? "Low" : "Found"),
                .init(title: "Allergens", value: allergenHits.isEmpty ? "None seen" : "\(min(allergenHits.count, 3)) found")
            ],
            suggestion: isLikelyFood ? suggestion(for: rating, sugarLevel: sugarLevel, additives: additiveHits) : "Retake a food ingredient label for a clearer result.",
            trustNote: aiInsightService.ingredientInsight(
                text: normalized,
                sugarLevel: sugarLevel,
                additiveHits: additiveHits,
                allergenHits: allergenHits,
                isLikelyFood: isLikelyFood
            ),
            healthRiskLevel: risk
        )
    }

    private func classifyDiet(_ text: String) -> DietType {
        if matches(in: text, markers: nonVegMarkers).isEmpty == false {
            return .nonVegetarian
        }
        if matches(in: text, markers: vegetarianMarkers).isEmpty == false {
            return .vegetarian
        }
        return text.isEmpty ? .uncertain : .vegan
    }

    private func matches(in text: String, markers: [String]) -> [String] {
        markers.filter { text.contains($0) }
    }

    private func eNumberMatches(in text: String) -> [String] {
        let pattern = #"e\s?\d{3,4}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }

    private func isLikelyFood(_ text: String) -> Bool {
        let foodSignals = [
            "ingredient", "ingredients", "nutrition", "sugar", "salt", "flour",
            "maida", "milk", "oil", "cocoa", "oat", "rice", "wheat", "protein",
            "fiber", "fibre", "spice", "flavour", "flavor", "preservative"
        ]
        let nonFoodSignals = [
            "detergent", "soap", "shampoo", "conditioner", "battery", "charger",
            "cosmetic", "external use", "medicine", "tablet", "capsule", "cleaner",
            "disinfectant", "toothpaste", "deodorant", "flammable", "warning",
            "keep out of reach", "do not ingest"
        ]

        if nonFoodSignals.contains(where: { text.contains($0) }) {
            return false
        }
        return foodSignals.contains(where: { text.contains($0) }) || text.split(separator: ",").count >= 3
    }

    private func verdict(for rating: HealthSummary.Rating, sugarLevel: String, additives: [String]) -> String {
        if sugarLevel == "High" { return "Okay, but high sugar" }
        if additives.count >= 3 { return "Processed, use occasionally" }
        switch rating {
        case .a: return "Good choice"
        case .b: return "Looks reasonable"
        case .c: return "Okay in moderation"
        case .d: return "Not healthy for daily use"
        case .e: return "Best as an occasional treat"
        }
    }

    private func suggestion(for rating: HealthSummary.Rating, sugarLevel: String, additives: [String]) -> String {
        if sugarLevel == "High" { return "Try a lower sugar alternative." }
        if additives.count >= 3 { return "Choose a shorter ingredient list." }
        return rating == .a || rating == .b ? "Good for a quick choice." : "Compare with a simpler option."
    }

    private func riskLevel(for rating: HealthSummary.Rating) -> String {
        switch rating {
        case .a, .b: return "Low"
        case .c: return "Medium"
        case .d, .e: return "High"
        }
    }

}
