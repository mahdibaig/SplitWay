import SwiftUI

/// Outer wrapper. Loads members + builds the VM once, then hands it to the
/// inner form which observes its `@Published` state.
struct AddExpenseView: View {
    @EnvironmentObject private var expenseService: ExpenseService
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var membersService: MembersService
    @EnvironmentObject private var groupService: GroupService

    @StateObject private var holder = AddExpenseVMHolder()

    var body: some View {
        NavigationStack {
            Group {
                if let vm = holder.viewModel {
                    AddExpenseForm(viewModel: vm)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.bg)
                }
            }
            .task {
                guard holder.viewModel == nil else { return }
                await membersService.refresh()
                await groupService.refresh()
                let groupsEnabled = householdService.currentHousehold?.groupsEnabled ?? false
                holder.viewModel = AddExpenseViewModel(
                    expenseService: expenseService,
                    householdService: householdService,
                    members: membersService.members,
                    groups: groupsEnabled ? groupService.groupsList : [],
                    groupMembership: groupsEnabled ? membersService.groupMembership : [:]
                )
            }
        }
    }
}

@MainActor
private final class AddExpenseVMHolder: ObservableObject {
    @Published var viewModel: AddExpenseViewModel?
}

/// Inner form. Observes the VM so amount edits, category picks, and split
/// changes actually re-render the UI and the Save button enables.
private struct AddExpenseForm: View {
    @ObservedObject var viewModel: AddExpenseViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCategoryPicker = false
    @State private var showReceiptScan = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.cardGap) {
                amountCard
                categoryCard
                descriptionCard
                dateCard
                splitCard
                paidByCard

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.cardLabel)
                        .foregroundStyle(Color.warn)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.cardPad)
                }
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.vertical, 16)
        }
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle("New expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "xmark") }
                    .foregroundStyle(Color.text1)
            }
            ToolbarItem(placement: .principal) {
                Button {
                    showReceiptScan = true
                } label: {
                    Image(systemName: "doc.text.viewfinder")
                        .foregroundStyle(Color.brand)
                }
                .accessibilityLabel("Scan receipt")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.save()
                        if viewModel.didSave { dismiss() }
                    }
                } label: {
                    if viewModel.isSaving { ProgressView() }
                    else { Text("Save").bold() }
                }
                .disabled(!viewModel.canSave)
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerView(selected: viewModel.category) { newValue in
                viewModel.category = newValue
                showCategoryPicker = false
            }
        }
        .fullScreenCover(isPresented: $showReceiptScan) {
            ReceiptScanFlow()
        }
    }

    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Amount").font(.cardLabel).foregroundStyle(Color.text2)
            HStack(spacing: 4) {
                Text("$").font(.system(size: 40, weight: .medium)).foregroundStyle(Color.text2)
                TextField("0.00", value: $viewModel.amount,
                          format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(Color.text1)
            }
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
                        .fill(Color.categoryBg(viewModel.category))
                    Image(systemName: viewModel.category.sfSymbol)
                        .foregroundStyle(Color.categoryFg(viewModel.category))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Category").font(.cardLabel).foregroundStyle(Color.text2)
                    Text(viewModel.category.displayName).font(.cardTitle).foregroundStyle(Color.text1)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Color.text3)
            }
            .padding(Spacing.cardPad)
            .background(Color.surface, in: .rect(cornerRadius: Radius.card))
        }
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Description").font(.cardLabel).foregroundStyle(Color.text2)
            TextField("What was it for?", text: $viewModel.description)
                .font(.cardTitle)
                .foregroundStyle(Color.text1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private var dateCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.tile).fill(Color.brandSoft)
                Image(systemName: "calendar").foregroundStyle(Color.brand)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("Date").font(.cardLabel).foregroundStyle(Color.text2)
                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Color.brand)
            }
            Spacer()
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private var splitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Split").font(.cardLabel).foregroundStyle(Color.text2)
                Spacer()
            }

            if viewModel.groupModeAvailable {
                Picker("Among", selection: $viewModel.granularity) {
                    Text("Individuals").tag(AddExpenseViewModel.SplitGranularity.individuals)
                    Text("Groups").tag(AddExpenseViewModel.SplitGranularity.groups)
                }
                .pickerStyle(.segmented)
            }

            Picker("Split type", selection: $viewModel.splitType) {
                ForEach([SplitType.equal, .percentages, .amounts, .shares], id: \.self) { t in
                    Text(t.displayName).tag(t)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.granularity == .groups {
                ForEach(viewModel.groupParticipantStates.indices, id: \.self) { idx in
                    groupSplitRow(idx: idx)
                }
            } else {
                ForEach(viewModel.participantStates.indices, id: \.self) { idx in
                    splitRow(idx: idx)
                }
            }
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    @ViewBuilder
    private func groupSplitRow(idx: Int) -> some View {
        let state = viewModel.groupParticipantStates[idx]

        HStack(spacing: 12) {
            Button {
                viewModel.groupParticipantStates[idx].isIncluded.toggle()
            } label: {
                Image(systemName: state.isIncluded ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(state.isIncluded ? Color.brand : Color.text3)
            }

            Text(state.emoji ?? "👥")
                .font(.system(size: 22))
                .frame(width: 32, height: 32)
                .background(Color.brandSoft, in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(state.name)
                    .font(.cardTitle)
                    .foregroundStyle(state.isIncluded ? Color.text1 : Color.text3)
                if !state.memberNames.isEmpty {
                    Text(state.memberNames.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(Color.text2)
                        .lineLimit(1)
                }
            }

            Spacer()

            if state.isIncluded {
                switch viewModel.splitType {
                case .equal, .excluded:
                    let shares = viewModel.resolvedGroupShares
                    if let share = shares[state.id] {
                        Text(CurrencyFormat.usd(share))
                            .font(.cardLabel)
                            .foregroundStyle(Color.text2)
                    }
                case .percentages:
                    valueField(value: $viewModel.groupParticipantStates[idx].inputValue, suffix: "%")
                case .amounts:
                    valueField(value: $viewModel.groupParticipantStates[idx].inputValue, prefix: "$")
                case .shares:
                    valueField(value: $viewModel.groupParticipantStates[idx].inputValue)
                }
            }
        }
    }

    @ViewBuilder
    private func splitRow(idx: Int) -> some View {
        let state = viewModel.participantStates[idx]
        let palette = AvatarPalette.pair(for: state.id)

        HStack(spacing: 12) {
            Button {
                viewModel.participantStates[idx].isIncluded.toggle()
            } label: {
                Image(systemName: state.isIncluded ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(state.isIncluded ? Color.brand : Color.text3)
            }

            ZStack {
                Circle().fill(palette.bg)
                if let emoji = state.avatarEmoji, !emoji.isEmpty {
                    Text(emoji).font(.system(size: 18))
                } else {
                    Text(initials(state.displayName))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(palette.fg)
                }
            }
            .frame(width: 32, height: 32)

            Text(state.displayName)
                .font(.cardTitle)
                .foregroundStyle(state.isIncluded ? Color.text1 : Color.text3)

            Spacer()

            if state.isIncluded {
                switch viewModel.splitType {
                case .equal, .excluded:
                    let shares = viewModel.resolvedShares
                    if let share = shares[state.id] {
                        Text(CurrencyFormat.usd(share))
                            .font(.cardLabel)
                            .foregroundStyle(Color.text2)
                    }
                case .percentages:
                    valueField(value: $viewModel.participantStates[idx].inputValue, suffix: "%")
                case .amounts:
                    valueField(value: $viewModel.participantStates[idx].inputValue, prefix: "$")
                case .shares:
                    valueField(value: $viewModel.participantStates[idx].inputValue)
                }
            }
        }
    }

    @ViewBuilder
    private func valueField(value: Binding<Decimal>, prefix: String? = nil, suffix: String? = nil) -> some View {
        HStack(spacing: 2) {
            if let prefix { Text(prefix).foregroundStyle(Color.text2) }
            TextField("0", value: value, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 64)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.surface2, in: .rect(cornerRadius: 8))
            if let suffix { Text(suffix).foregroundStyle(Color.text2) }
        }
    }

    private var paidByCard: some View {
        let payer = viewModel.participantStates.first { $0.id == viewModel.paidByUserID }
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.tile).fill(Color.brandSoft)
                Image(systemName: "wallet.pass.fill").foregroundStyle(Color.brand)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("Paid by").font(.cardLabel).foregroundStyle(Color.text2)
                Text(payer?.displayName ?? "Pick someone")
                    .font(.cardTitle).foregroundStyle(Color.text1)
            }
            Spacer()

            Menu {
                ForEach(viewModel.participantStates) { state in
                    Button(state.displayName) { viewModel.paidByUserID = state.id }
                }
            } label: {
                Image(systemName: "chevron.up.chevron.down").foregroundStyle(Color.text3)
            }
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}

#Preview {
    let services = ServiceContainer.preview()
    return AddExpenseView()
        .environmentObject(services.expenseService)
        .environmentObject(services.householdService)
        .environmentObject(services.membersService)
}
