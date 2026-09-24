import Foundation
import NaturalLanguage

struct FoodChatService {
    func answer(to question: String, turn: Int, recentReplies: [String]) -> String {
        let text = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = text.lowercased()

        guard text.isEmpty == false else {
            return pick(
                [
                    "Ask me a food question. Sugar, sodium, maida, protein, additives, or diet fit are all fair game.",
                    "Give me a label mystery to solve. I am best with ingredients, nutrition, and food choices."
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        guard isFoodRelated(normalized) else {
            return pick(
                [
                    "I am staying in my food lane here. Ask me about sugar, sodium, ingredients, allergens, kids, elders, or diet suitability.",
                    "That one is outside the kitchen. Toss me a food-label question and I will help without making it boring."
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        if containsAny(normalized, ["sugar", "glucose", "fructose", "syrup", "sweet"]) {
            return pick(
                [
                    "Sugar is the quick-energy guest that can overstay. If it is high, keep it occasional and compare with a lower-sugar option.",
                    "High sugar is not a panic button, but it does add up fast. For daily use, I would look for a lower-sugar choice.",
                    "If sugar appears early on the label, the product is probably sweeter than it looks. Good sometimes, less great as an everyday habit."
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        if containsAny(normalized, ["sodium", "salt", "salty"]) {
            return pick(
                [
                    "Sodium is sneaky because small packaged foods can stack up across the day. Lower-sodium is usually easier for regular eating.",
                    "Salt is not the villain, but high sodium every day can be a lot. Compare similar products and pick the calmer label.",
                    "If sodium is high, treat it like a check-engine light for frequent use. Occasional is fine; daily deserves a comparison."
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        if containsAny(normalized, ["maida", "refined flour", "white flour"]) {
            return pick(
                [
                    "Maida is refined flour, usually lower in fiber than whole grains. It is fine sometimes, but higher-fiber options keep you fuller.",
                    "Maida gives soft texture, not much fiber. If this is a daily food, whole-grain or higher-fiber options usually win.",
                    "Refined flour is the smooth talker of ingredients. Tasty, yes, but not very filling compared with whole grains."
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        if containsAny(normalized, ["protein", "gym", "fitness", "workout"]) {
            return pick(
                [
                    "For fitness, look for useful protein without a sugar parade. Good protein plus moderate sugar is the sweet spot.",
                    "Protein helps with fullness and recovery. If sugar is doing all the heavy lifting, it is more snack than fitness food.",
                    "Gym-friendly usually means decent protein, not too much added sugar, and ingredients you can actually understand."
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        if containsAny(normalized, ["kid", "child", "children", "baby"]) {
            return pick(
                [
                    "For kids, I would keep high sugar and long ingredient lists occasional. Lower sugar and simpler labels are easier everyday picks.",
                    "Kid-friendly does not need to mean boring. Look for lower sugar, recognizable ingredients, and portions that make sense.",
                    "If the label reads like a science fair project and sugar is high, make it occasional for kids."
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        if containsAny(normalized, ["elder", "senior", "old age", "parents"]) {
            return pick(
                [
                    "For elders, sodium is the first label check. If it is high, compare with a lower-sodium alternative.",
                    "Elder-friendly usually means gentle on sodium and easy to digest. I would compare salt levels before choosing.",
                    "For parents or seniors, high sodium deserves a second look. A lower-salt option can be the quieter daily choice."
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        if containsAny(normalized, ["vegan", "vegetarian", "non veg", "non-veg", "gelatin", "rennet", "whey", "casein"]) {
            return pick(
                [
                    "Diet check: gelatin, fish oil, carmine, chicken, beef, or pork suggest non-veg. Whey, casein, milk, cheese, and butter are vegetarian but not vegan.",
                    "For vegan labels, watch the quiet dairy words: whey, casein, milk powder, butter, and cheese. Gelatin or fish oil means not vegetarian.",
                    "Vegetarian and vegan are cousins, not twins. Dairy ingredients may pass vegetarian, but they do not pass vegan."
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        if containsAny(normalized, ["allergy", "allergen", "peanut", "milk", "gluten", "soy", "egg", "sesame"]) {
            return pick(
                [
                    "For allergies, the package label is the boss. Check allergen statements and avoid the product if the wording is unclear.",
                    "Allergen check needs zero guesswork. If peanut, milk, gluten, soy, egg, or sesame matters, confirm on the official label.",
                    "When allergies are involved, cautious is smart. The app can help spot words, but the package label gets final say."
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        if containsAny(normalized, ["additive", "preservative", "msg", "e-number", "e number", "emulsifier", "flavour", "flavor"]) {
            return pick(
                [
                    "Additives do not automatically mean unsafe, but they often mean more processing. A shorter ingredient list is easier to compare.",
                    "E-numbers and preservatives are label signals, not instant danger signs. I use them to spot how processed the product may be.",
                    "If additives are everywhere, the product is probably more processed. Not forbidden, just better as a sometimes choice."
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        if containsAny(normalized, ["scan", "barcode", "ingredient", "photo", "ocr"]) {
            return pick(
                [
                    "Scan the barcode first. If the product is missing, scan ingredients with good light, steady hands, and text inside the box.",
                    "For OCR, lighting is half the magic. Keep the label flat, avoid blur, and let the text sit inside the guide box.",
                    "Barcode for speed, ingredient photo for backup. That combo gives the app its best chance to understand the product."
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        if containsAny(normalized, ["healthy", "good", "bad", "daily", "eat"]) {
            return pick(
                [
                    "For daily eating, start with sugar, sodium, and ingredient length. Lower, calmer, shorter is usually easier to live with.",
                    "A good daily pick usually has moderate sugar, reasonable sodium, and a label that does not need a translator.",
                    "Do not chase perfect food. Just compare: less sugar, less sodium, more fiber, simpler ingredients."
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        let topic = bestFoodTerm(from: text)
        if let topic {
            return pick(
                [
                    "For \(topic), compare similar products and check sugar, sodium, and ingredient length. Give me one of those and I will zoom in.",
                    "\(topic.capitalized) is worth checking against the full label. Want me to look at sugar, sodium, additives, or diet fit next?",
                    "I can help with \(topic), but I need one more clue. Is your concern sugar, salt, protein, ingredients, or suitability?"
                ],
                turn: turn,
                recentReplies: recentReplies
            )
        }

        return pick(
            [
                "I can help, but I need a clearer food clue. Ask about sugar, sodium, maida, additives, allergens, vegan status, kids, or elders.",
                "My food brain needs one more breadcrumb. Is this about sugar, salt, protein, ingredients, or who the product suits?",
                "I am close, but not quite there. Paste a label word or ask something like: is this okay for daily use?"
            ],
            turn: turn,
            recentReplies: recentReplies
        )
    }

    private func isFoodRelated(_ text: String) -> Bool {
        let foodTerms = [
            "food", "product", "ingredient", "nutrition", "sugar", "salt", "sodium",
            "protein", "fat", "fiber", "fibre", "calorie", "maida", "flour", "oil",
            "milk", "wheat", "rice", "snack", "drink", "juice", "bread", "chocolate",
            "vegan", "vegetarian", "allergy", "allergen", "kids", "elder", "barcode",
            "scan", "healthy", "eat", "daily", "additive", "preservative"
        ]
        return foodTerms.contains { text.contains($0) }
    }

    private func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains { text.contains($0) }
    }

    private func pick(_ options: [String], turn: Int, recentReplies: [String]) -> String {
        let start = abs(turn) % max(options.count, 1)
        for offset in 0..<options.count {
            let candidate = options[(start + offset) % options.count]
            if recentReplies.contains(candidate) == false {
                return candidate
            }
        }
        return options[start]
    }

    private func bestFoodTerm(from text: String) -> String? {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        let range = text.startIndex..<text.endIndex
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        var result: String?

        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            guard tag == .noun || tag == .otherWord else { return true }
            let word = String(text[tokenRange]).lowercased()
            guard word.count > 3 else { return true }
            result = word
            return false
        }

        return result
    }
}
