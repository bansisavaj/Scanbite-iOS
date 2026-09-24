import Foundation

@MainActor
final class ScannerViewModel: ObservableObject {
    @Published var scannedBarcode: BarcodeRoute?
    @Published var manualBarcode = ""
    @Published var isTorchOn = false

    func handleScannedBarcode(_ code: String) {
        guard scannedBarcode == nil else { return }
        scannedBarcode = BarcodeRoute(value: code)
    }
}

struct BarcodeRoute: Identifiable, Hashable {
    let value: String
    var id: String { value }
}
