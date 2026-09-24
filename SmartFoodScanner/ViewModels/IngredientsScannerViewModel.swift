import UIKit

@MainActor
final class IngredientsScannerViewModel: ObservableObject {
    @Published var analysis: IngredientAnalysis?
    @Published var isProcessing = false
    @Published var prompt: String?

    private let ocrService = OCRService()
    private let analysisEngine = IngredientAnalysisEngine()

    func process(image: UIImage) async {
        isProcessing = true
        prompt = nil

        guard let text = await ocrService.extractText(from: image), text.count >= 24 else {
            prompt = "Retake photo"
            isProcessing = false
            return
        }

        analysis = analysisEngine.analyzeIngredients(text: text)
        isProcessing = false
    }

    func retry() {
        analysis = nil
        prompt = nil
    }
}
