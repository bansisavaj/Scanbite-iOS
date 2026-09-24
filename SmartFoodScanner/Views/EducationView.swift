import SwiftUI

struct EducationView: View {
    private let checks = [
        "Read the first three ingredients first.",
        "Watch for sugar names like syrup, glucose, and fructose.",
        "Check sodium when buying snacks, sauces, and ready meals.",
        "Short ingredient lists are usually easier to understand.",
        "Look for gelatin, rennet, whey, casein, carmine, and fish oil when checking diet fit."
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("How to Check Food Products")
                    .font(.largeTitle.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(checks, id: \.self) { check in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.green)
                            Text(check)
                                .font(.body)
                                .lineSpacing(3)
                        }
                    }
                }
                .cardStyle()
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AppAnalyticsService.shared.log(.educationViewed)
        }
    }
}
