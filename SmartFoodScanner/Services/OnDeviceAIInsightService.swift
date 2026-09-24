import Foundation
import NaturalLanguage

struct OnDeviceAIInsightService {
    func productInsight(
        product: FoodProduct,
        sugar: Nutrition.Level,
        protein: String,
        ultraProcessed: Bool,
        isLikelyFood: Bool
    ) -> String {
        guard isLikelyFood else {
            return "On-device AI did not find enough food label signals here. Please scan a real food package or ingredient label before trusting this result."
        }

        let text = product.ingredientsText.lowercased()
        let terms = keyTerms(from: product.ingredientsText)

        if sugar == .high {
            return "On-device AI noticed sugar is a key signal. Frequent high-sugar choices can add up quickly, so a lower-sugar option may be better for regular use."
        }

        if text.contains("sodium") || text.contains("salt") || product.nutrition.sodiumLevel == .high {
            return "On-device AI highlighted sodium because salty packaged foods can raise total daily salt intake without feeling obvious. Comparing lower-sodium options can help."
        }

        if text.contains("maida") || text.contains("refined flour") {
            return "On-device AI noticed refined flour or maida. These are usually lower in fiber than whole grains, so higher-fiber options may keep you full for longer."
        }

        if ultraProcessed {
            return "On-device AI found signs of a more processed ingredient list. This does not mean the food is unsafe, but simpler labels are often easier to compare."
        }

        if protein == "Low" {
            return "On-device AI noticed protein looks low. This food may not keep you full for long by itself, so pairing it with a protein-rich item can help."
        }

        if let first = terms.first {
            return "On-device AI reviewed the label and noticed \(first). Use this as a quick guide, then compare similar products when possible."
        }

        return "On-device AI checked the main label signals and did not find a strong concern. Use this as a quick guide, not medical advice."
    }

    func ingredientInsight(
        text: String,
        sugarLevel: String,
        additiveHits: [String],
        allergenHits: [String],
        isLikelyFood: Bool
    ) -> String {
        guard isLikelyFood else {
            return "On-device AI did not recognize this as a food ingredient label. Retake a photo of an edible product label for a more reliable result."
        }

        let normalized = text.lowercased()
        if sugarLevel == "High" {
            return "On-device AI found multiple sugar signals. High-sugar foods are usually better as occasional choices, especially for kids."
        }

        if normalized.contains("sodium") || normalized.contains("salt") {
            return "On-device AI noticed salt or sodium. For regular use, lower-sodium products are often easier to fit into a balanced day."
        }

        if normalized.contains("maida") || normalized.contains("refined flour") {
            return "On-device AI noticed maida or refined flour. Whole-grain or higher-fiber options may support steadier fullness."
        }

        if !additiveHits.isEmpty {
            return "On-device AI found additive signals like preservatives, E-numbers, or flavouring terms. This mainly means the label is more processed, not automatically unsafe."
        }

        if !allergenHits.isEmpty {
            return "On-device AI found possible allergen words. Please confirm the package label carefully if allergies matter for you."
        }

        let terms = keyTerms(from: text)
        if let first = terms.first {
            return "On-device AI reviewed the ingredient text and noticed \(first). The score is a quick guide to help you compare products faster."
        }

        return "On-device AI checked the ingredient text for common food signals. Use the result as a quick guide, not medical advice."
    }

    private func keyTerms(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var terms: [String] = []
        let range = text.startIndex..<text.endIndex
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]

        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            guard tag == .noun || tag == .otherWord else { return true }
            let word = String(text[tokenRange]).lowercased()
            if isUsefulTerm(word), terms.contains(word) == false {
                terms.append(word)
            }
            return terms.count < 3
        }

        return terms
    }

    private func isUsefulTerm(_ word: String) -> Bool {
        let stopWords = [
            "and", "or", "with", "from", "contains", "ingredient", "ingredients",
            "may", "product", "natural", "added", "total", "per", "serving"
        ]
        guard word.count > 3, stopWords.contains(word) == false else { return false }
        return word.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil
    }
}
