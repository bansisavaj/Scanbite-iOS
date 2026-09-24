import SwiftUI

struct ScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @State private var showManualEntry = false

    var body: some View {
        ZStack {
            BarcodeScannerView(
                isTorchOn: viewModel.isTorchOn,
                onCodeFound: viewModel.handleScannedBarcode
            )
            .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white, lineWidth: 3)
                .frame(width: 260, height: 160)
                .shadow(color: .black.opacity(0.25), radius: 8)

            VStack {
                HStack {
                    Spacer()
                    Button {
                        viewModel.isTorchOn.toggle()
                    } label: {
                        Image(systemName: viewModel.isTorchOn ? "bolt.fill" : "bolt.slash")
                            .font(.title3)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Toggle flash")
                }
                .padding()

                Spacer()

                Button {
                    showManualEntry = true
                } label: {
                    Image(systemName: "keyboard")
                        .font(.title3)
                        .padding(14)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Enter barcode manually")
                .padding(.bottom, 24)
            }
        }
        .navigationDestination(item: $viewModel.scannedBarcode) { route in
            ProductResultView(barcode: route.value)
        }
        .onAppear {
            AppAnalyticsService.shared.log(.barcodeScannerOpened)
        }
        .sheet(isPresented: $showManualEntry) {
            NavigationStack {
                Form {
                    TextField("Barcode", text: $viewModel.manualBarcode)
                        .keyboardType(.numberPad)

                    NavigationLink("Search") {
                        ProductResultView(barcode: viewModel.manualBarcode)
                    }
                    .disabled(viewModel.manualBarcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .navigationTitle("Manual Entry")
            }
        }
    }
}
