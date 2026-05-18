import SwiftUI

/// Sheet shown from the Home banner when one or more variable-amount recurring
/// templates are due. User enters the amount per template and saves all at once.
struct VariableAmountSheet: View {
    @EnvironmentObject private var recurringService: RecurringService
    @Environment(\.dismiss) private var dismiss

    /// Per-template amount being entered. Keyed by template id.
    @State private var amounts: [UUID: Decimal] = [:]
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.cardGap) {
                    explainer

                    ForEach(recurringService.pendingVariable) { template in
                        templateCard(template)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.cardLabel)
                            .foregroundStyle(Color.warn)
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, 16)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Bills due")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Later") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await logAll() }
                    } label: {
                        if isWorking { ProgressView() }
                        else { Text("Log all").bold() }
                    }
                    .disabled(!hasAnyAmount || isWorking)
                }
            }
        }
    }

    private var explainer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Enter this month's amounts")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
            Text("Fill in just the ones you know. Anything you skip stays due until later.")
                .font(.caption)
                .foregroundStyle(Color.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func templateCard(_ template: RecurringTemplate) -> some View {
        let binding = Binding(
            get: { amounts[template.id] ?? 0 },
            set: { amounts[template.id] = $0 }
        )
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.tile)
                    .fill(Color.categoryBg(template.category))
                Image(systemName: template.category.sfSymbol)
                    .foregroundStyle(Color.categoryFg(template.category))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(template.description)
                    .font(.cardTitle)
                    .foregroundStyle(Color.text1)
                Text("Due \(template.nextOccurrence.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.caption)
                    .foregroundStyle(Color.text2)
            }

            Spacer()

            HStack(spacing: 2) {
                Text("$").foregroundStyle(Color.text2)
                TextField("0.00", value: binding,
                          format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.surface2, in: .rect(cornerRadius: 8))
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private var hasAnyAmount: Bool {
        amounts.contains { $0.value > 0 }
    }

    private func logAll() async {
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        for template in recurringService.pendingVariable {
            guard let amt = amounts[template.id], amt > 0 else { continue }
            do {
                try await recurringService.logVariable(template, amount: amt)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }
        dismiss()
    }
}
