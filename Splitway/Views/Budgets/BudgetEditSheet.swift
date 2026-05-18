import SwiftUI

struct BudgetEditSheet: View {
    enum Mode {
        case new(category: ExpenseCategory)
        case edit(budget: Budget)

        var category: ExpenseCategory {
            switch self {
            case .new(let c):      return c
            case .edit(let b):     return b.category
            }
        }

        var initialLimit: Decimal {
            switch self {
            case .new:             return 0
            case .edit(let b):     return b.monthlyLimit
            }
        }

        var isEdit: Bool {
            if case .edit = self { return true }
            return false
        }
    }

    let mode: Mode
    @EnvironmentObject private var budgetService: BudgetService
    @Environment(\.dismiss) private var dismiss

    @State private var limit: Decimal = 0
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.cardGap) {
                    categoryCard

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Monthly limit").font(.cardLabel).foregroundStyle(Color.text2)
                        HStack(spacing: 4) {
                            Text("$").font(.system(size: 40, weight: .medium)).foregroundStyle(Color.text2)
                            TextField("0.00", value: $limit,
                                      format: .number.precision(.fractionLength(0...2)))
                                .keyboardType(.decimalPad)
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(Color.text1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.cardPad)
                    .background(Color.surface, in: .rect(cornerRadius: Radius.card))

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.cardLabel)
                            .foregroundStyle(Color.warn)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if mode.isEdit {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("Remove budget")
                                .font(.cardLabel)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.warnSoft, in: .rect(cornerRadius: Radius.pill))
                                .foregroundStyle(Color.warn)
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, 16)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle(mode.isEdit ? "Edit budget" : "New budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isWorking { ProgressView() }
                        else { Text("Save").bold() }
                    }
                    .disabled(limit <= 0 || isWorking)
                }
            }
            .onAppear { limit = mode.initialLimit }
            .confirmationDialog(
                "Remove this budget?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    Task { await delete() }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var categoryCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.tile)
                    .fill(Color.categoryBg(mode.category))
                Image(systemName: mode.category.sfSymbol)
                    .foregroundStyle(Color.categoryFg(mode.category))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("Category").font(.cardLabel).foregroundStyle(Color.text2)
                Text(mode.category.displayName).font(.cardTitle).foregroundStyle(Color.text1)
            }

            Spacer()
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private func save() async {
        guard limit > 0 else { return }
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        do {
            _ = try await budgetService.setBudget(category: mode.category, monthlyLimit: limit)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete() async {
        guard case .edit(let budget) = mode else { return }
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        do {
            try await budgetService.deleteBudget(id: budget.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

