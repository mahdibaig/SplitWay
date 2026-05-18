import SwiftUI

/// Settings > Money > Export to CSV. Generates the file then offers the
/// system share sheet via ShareLink. Wrapped in ProGate by the caller.
struct CSVExportView: View {
    @EnvironmentObject private var services: ServiceContainer

    @State private var fileURL: URL?
    @State private var isGenerating = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.cardGap) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Export your data").font(.cardTitle).foregroundStyle(Color.text1)
                    Text("Creates a CSV with every expense: date, description, category, amount, who paid, the split type, and each member's share. It's your data, take it anywhere.")
                        .font(.cardLabel)
                        .foregroundStyle(Color.text2)
                    Text("\(services.expenseExportService.expenseCount) expense\(services.expenseExportService.expenseCount == 1 ? "" : "s") to export.")
                        .font(.caption)
                        .foregroundStyle(Color.text3)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.cardPad)
                .background(Color.surface, in: .rect(cornerRadius: Radius.card))

                if let fileURL {
                    ShareLink(item: fileURL) {
                        Label("Share CSV", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                            .foregroundStyle(Color.ctaText)
                    }
                } else {
                    Button {
                        Task {
                            isGenerating = true
                            fileURL = await services.expenseExportService.exportFile()
                            isGenerating = false
                        }
                    } label: {
                        Group {
                            if isGenerating { ProgressView().tint(Color.ctaText) }
                            else { Text("Generate CSV") }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                        .foregroundStyle(Color.ctaText)
                    }
                    .disabled(isGenerating || services.expenseExportService.expenseCount == 0)
                }
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.vertical, 16)
        }
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle("Export to CSV")
        .navigationBarTitleDisplayMode(.inline)
        // Regenerate if expenses change while the screen is open.
        .onChange(of: services.expenseExportService.expenseCount) { _, _ in
            fileURL = nil
        }
    }
}
