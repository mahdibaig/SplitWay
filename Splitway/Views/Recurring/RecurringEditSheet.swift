import SwiftUI

struct RecurringEditSheet: View {
    enum Mode {
        case new
        case edit(template: RecurringTemplate)

        var isEdit: Bool {
            if case .edit = self { return true }
            return false
        }
    }

    let mode: Mode
    @EnvironmentObject private var recurringService: RecurringService
    @Environment(\.dismiss) private var dismiss

    @State private var description: String = ""
    @State private var category: ExpenseCategory = .utilities
    @State private var amount: Decimal = 0
    @State private var isVariableAmount: Bool = false
    @State private var dayOfMonth: Int = 1
    @State private var isActive: Bool = true

    @State private var showCategoryPicker = false
    @State private var showDeleteConfirm = false
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.cardGap) {
                    descriptionCard
                    categoryCard
                    amountSection
                    dayOfMonthCard
                    activeToggleCard

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
                            Text("Remove recurring bill")
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
            .navigationTitle(mode.isEdit ? "Edit recurring" : "New recurring")
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
                    .disabled(!canSave || isWorking)
                }
            }
            .onAppear(perform: loadInitial)
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(selected: category) { newValue in
                    category = newValue
                    showCategoryPicker = false
                }
            }
            .confirmationDialog(
                "Remove this recurring bill?",
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

    private var canSave: Bool {
        !description.trimmingCharacters(in: .whitespaces).isEmpty
            && dayOfMonth >= 1 && dayOfMonth <= 31
            && (isVariableAmount || amount > 0)
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What is it?").font(.cardLabel).foregroundStyle(Color.text2)
            TextField("Rent, internet, electric...", text: $description)
                .font(.cardTitle)
                .foregroundStyle(Color.text1)
                .textInputAutocapitalization(.sentences)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private var categoryCard: some View {
        Button { showCategoryPicker = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.tile)
                        .fill(Color.categoryBg(category))
                    Image(systemName: category.sfSymbol)
                        .foregroundStyle(Color.categoryFg(category))
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Category").font(.cardLabel).foregroundStyle(Color.text2)
                    Text(category.displayName).font(.cardTitle).foregroundStyle(Color.text1)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Color.text3)
            }
            .padding(Spacing.cardPad)
            .background(Color.surface, in: .rect(cornerRadius: Radius.card))
        }
    }

    private var amountSection: some View {
        VStack(spacing: Spacing.cardGap) {
            HStack(spacing: 12) {
                Toggle(isOn: $isVariableAmount) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Variable amount")
                            .font(.cardTitle)
                            .foregroundStyle(Color.text1)
                        Text("Prompt you each month, like a utility bill.")
                            .font(.caption)
                            .foregroundStyle(Color.text2)
                    }
                }
                .tint(Color.brand)
            }
            .padding(Spacing.cardPad)
            .background(Color.surface, in: .rect(cornerRadius: Radius.card))

            if !isVariableAmount {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Monthly amount").font(.cardLabel).foregroundStyle(Color.text2)
                    HStack(spacing: 4) {
                        Text("$").font(.system(size: 36, weight: .medium)).foregroundStyle(Color.text2)
                        TextField("0.00", value: $amount,
                                  format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(Color.text1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.cardPad)
                .background(Color.surface, in: .rect(cornerRadius: Radius.card))
            }
        }
    }

    private var dayOfMonthCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.tile).fill(Color.brandSoft)
                Image(systemName: "calendar").foregroundStyle(Color.brand)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("Day of month").font(.cardLabel).foregroundStyle(Color.text2)
                Picker("Day", selection: $dayOfMonth) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.brand)
            }
            Spacer()
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private var activeToggleCard: some View {
        Toggle(isOn: $isActive) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Active").font(.cardTitle).foregroundStyle(Color.text1)
                Text("Pause to stop auto-logging without deleting.")
                    .font(.caption)
                    .foregroundStyle(Color.text2)
            }
        }
        .tint(Color.brand)
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private func loadInitial() {
        guard case .edit(let template) = mode else { return }
        description = template.description
        category = template.category
        amount = template.amount ?? 0
        isVariableAmount = template.isVariableAmount
        dayOfMonth = template.dayOfMonth
        isActive = template.isActive
    }

    private func save() async {
        guard canSave else { return }
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        do {
            switch mode {
            case .new:
                _ = try await recurringService.create(
                    description: description.trimmingCharacters(in: .whitespaces),
                    category: category,
                    amount: isVariableAmount ? nil : amount,
                    isVariableAmount: isVariableAmount,
                    dayOfMonth: dayOfMonth,
                    isActive: isActive
                )
            case .edit(let template):
                var updated = template
                updated.description = description.trimmingCharacters(in: .whitespaces)
                updated.category = category
                updated.amount = isVariableAmount ? nil : amount
                updated.isVariableAmount = isVariableAmount
                updated.isActive = isActive
                if updated.dayOfMonth != dayOfMonth {
                    updated.dayOfMonth = dayOfMonth
                    updated.nextOccurrence = RecurrenceCalendar.initialOccurrence(dayOfMonth: dayOfMonth)
                }
                try await recurringService.update(updated)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete() async {
        guard case .edit(let template) = mode else { return }
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        do {
            try await recurringService.delete(id: template.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
