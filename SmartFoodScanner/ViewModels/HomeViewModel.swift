import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var manualBarcode = ""
    @Published var showManualSearch = false
}
