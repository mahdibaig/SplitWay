import SwiftUI

/// Review screen for a scanned receipt. Each line item shows a status badge
/// (known/new) and tappable assignment summary. The assignment sheet now has
/// a three-option "remember" picker so future scans pre-fill from rules.
struct ReceiptReviewView: View {
    let draft: ReceiptDraft
    let image: UIImage
    let members: [HouseholdMember]
    let onSave: ([ReviewItem], ExpenseCategory, String, Date) async -> Void
    let onCancel: () -> Void

    @State private var items: [ReviewItem] = []
    @State private var category: ExpenseCategory = .groceries
    @State private var descriptionText: String = ""
    @State private var date: Date = Date()
    @State private var assigningItemID: UUID?
    @State private var quantityItemID: UUID?
    @State private var categoryItemID: UUID?
    @State private var showCategoryPicker = false
    @State private var isWorking = false

    // Bulk-select mode: when on, each row shows a checkbox, tapping rows
    // adds to selection, and a floating bar offers bulk actions.
    @State private var selectMode: Bool = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var showBulkAssign = false
    @State private var showBulkCategory = false
    @State private var showOCRDebug = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.cardGap) {
                receiptThumbnail
                recognitionBanner
                summaryCard
                descriptionCard
                categoryCard
                dateCard
                itemsSection
                ocrDebugSection
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.vertical, 16)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await commit() }
                } label: {
                    if isWorking { ProgressView() }
                    else { Text("Save").bold() }
                }
                .disabled(items.isEmpty || isWorking)
            }
        }
        .onAppear(perform: loadInitial)
        .sheet(item: $assigningItemID) { id in
            if let idx = items.firstIndex(where: { $0.id == id }) {
                LineItemAssignmentSheet(
                    itemName: items[idx].lineItem.displayName,
                    members: members,
                    assignedIDs: Set(items[idx].lineItem.assignedToUserIDs),
                    rememberChoice: items[idx].rememberChoice,
                    onSave: { newAssignment, newRemember in
                        items[idx].lineItem.assignedToUserIDs = Array(newAssignment)
                        items[idx].rememberChoice = newRemember
                        assigningItemID = nil
                    }
                )
            }
        }
        .sheet(item: $quantityItemID) { id in
            if let idx = items.firstIndex(where: { $0.id == id }) {
                LineItemQuantitySheet(
                    itemName: items[idx].lineItem.displayName,
                    amount: items[idx].lineItem.amount,
                    members: members,
                    quantityPerUser: items[idx].lineItem.quantityPerUser ?? [:],
                    onSave: { newMap in
                        items[idx].lineItem.quantityPerUser = newMap.isEmpty ? nil : newMap
                        quantityItemID = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerView(selected: category) { newValue in
                category = newValue
                showCategoryPicker = false
            }
        }
        .sheet(isPresented: $showBulkAssign) {
            LineItemAssignmentSheet(
                itemName: "\(selectedIDs.count) selected item\(selectedIDs.count == 1 ? "" : "s")",
                members: members,
                assignedIDs: [],
                rememberChoice: .justThisTime,
                onSave: { newAssignment, _ in
                    applyBulkAssignment(newAssignment)
                    showBulkAssign = false
                }
            )
        }
        .sheet(isPresented: $showBulkCategory) {
            CategoryPickerView(selected: category) { newValue in
                applyBulkCategory(newValue)
                showBulkCategory = false
            }
        }
        .sheet(item: $categoryItemID) { id in
            if let idx = items.firstIndex(where: { $0.id == id }) {
                CategoryPickerView(
                    selected: items[idx].lineItem.category ?? category
                ) { newValue in
                    items[idx].lineItem.category = newValue
                    categoryItemID = nil
                }
            }
        }
    }

    private var receiptThumbnail: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: 200)
            .clipShape(.rect(cornerRadius: Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
    }

    @ViewBuilder
    private var recognitionBanner: some View {
        if let notice = draft.fallbackNotice {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.warn)
                Text(notice)
                    .font(.cardLabel)
                    .foregroundStyle(Color.text1)
                Spacer()
            }
            .padding(Spacing.cardPad)
            .background(Color.warnSoft, in: .rect(cornerRadius: Radius.card))
        }

        let known = items.filter { $0.matchedRule != nil }.count
        let new = items.count - known
        if !items.isEmpty {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.success)
                VStack(alignment: .leading, spacing: 2) {
                    if known == 0 {
                        Text("\(new) new item\(new == 1 ? "" : "s") to review.")
                            .font(.cardLabel.weight(.medium))
                            .foregroundStyle(Color.text1)
                    } else if new == 0 {
                        Text("Recognized \(known) item\(known == 1 ? "" : "s") from past receipts.")
                            .font(.cardLabel.weight(.medium))
                            .foregroundStyle(Color.text1)
                    } else {
                        Text("Recognized \(known) item\(known == 1 ? "" : "s") from past receipts. \(new) new to review.")
                            .font(.cardLabel.weight(.medium))
                            .foregroundStyle(Color.text1)
                    }
                    Text("Tap a category chip below to change how an item is categorized. Use Select for bulk actions.")
                        .font(.caption)
                        .foregroundStyle(Color.text2)
                }
                Spacer()
            }
            .padding(Spacing.cardPad)
            .background(Color.successSoft, in: .rect(cornerRadius: Radius.card))
        }
    }

    private var summaryCard: some View {
        let total = items.reduce(Decimal.zero) { $0 + $1.lineItem.amount }
        return VStack(alignment: .leading, spacing: 4) {
            Text(draft.merchant ?? "Receipt").font(.cardTitle).foregroundStyle(Color.text1)
            Text("\(items.count) line item\(items.count == 1 ? "" : "s") · \(CurrencyFormat.usd(total)) total")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
            if items.isEmpty {
                Text("No line items detected. You can add them by hand with the + button below, or cancel and use manual entry.")
                    .font(.caption)
                    .foregroundStyle(Color.text3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Description").font(.cardLabel).foregroundStyle(Color.text2)
            TextField(draft.merchant ?? "Receipt", text: $descriptionText)
                .font(.cardTitle)
                .foregroundStyle(Color.text1)
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
                    Image(systemName: category.sfSymbol).foregroundStyle(Color.categoryFg(category))
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

    private var dateCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.tile).fill(Color.brandSoft)
                Image(systemName: "calendar").foregroundStyle(Color.brand)
            }
            .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("Date").font(.cardLabel).foregroundStyle(Color.text2)
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Color.brand)
            }
            Spacer()
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    /// Collapsible panel showing exactly what Vision OCR returned. Helps
    /// debug "why is this item missing?" — if a line is in the OCR output
    /// but not in the parsed items, it's a parser issue; if it's not in
    /// the OCR output at all, Vision dropped it (try a better photo).
    @ViewBuilder
    private var ocrDebugSection: some View {
        let lines = draft.rawLines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    showOCRDebug.toggle()
                } label: {
                    HStack {
                        Image(systemName: "eye")
                            .font(.caption)
                            .foregroundStyle(Color.text2)
                        Text(showOCRDebug ? "Hide raw OCR text" : "View raw OCR text (\(lines.count) lines)")
                            .font(.cardLabel)
                            .foregroundStyle(Color.text2)
                        Spacer()
                        Image(systemName: showOCRDebug ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(Color.text3)
                    }
                }
                .buttonStyle(.plain)

                if showOCRDebug {
                    Text("If an item is missing from the list above but appears below, the parser missed it. If it's not below either, Vision didn't see it (try a clearer photo).")
                        .font(.caption)
                        .foregroundStyle(Color.text3)
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { idx, line in
                            HStack(alignment: .top, spacing: 6) {
                                Text("\(idx + 1).")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(Color.text3)
                                    .frame(width: 24, alignment: .trailing)
                                Text(line)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(Color.text1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.surface2, in: .rect(cornerRadius: 8))
                }
            }
            .padding(Spacing.cardPad)
            .background(Color.surface, in: .rect(cornerRadius: Radius.card))
        }
    }

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("Line items").font(.cardLabel).foregroundStyle(Color.text2)
                Spacer()
                if !items.isEmpty {
                    Button {
                        selectMode.toggle()
                        if !selectMode { selectedIDs.removeAll() }
                    } label: {
                        Text(selectMode ? "Done" : "Select")
                            .font(.cardLabel)
                            .foregroundStyle(Color.brand)
                    }
                }
                if !selectMode {
                    Button {
                        let newItem = LineItem(
                            id: UUID(),
                            itemName: "",
                            displayName: "",
                            normalizedItemName: "",
                            amount: 0,
                            quantity: 1,
                            assignedToUserIDs: [],
                            // Default the new row to whatever overall category
                            // is currently set, so the user can hit Add and
                            // start typing without an extra tap.
                            category: category
                        )
                        items.append(ReviewItem(
                            lineItem: newItem,
                            matchedRule: nil,
                            rememberChoice: .justThisTime
                        ))
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.cardLabel)
                            .foregroundStyle(Color.brand)
                    }
                }
            }

            if selectMode {
                bulkActionBar
            }

            ForEach(items.indices, id: \.self) { idx in
                lineItemRow(idx: idx)
            }
        }
    }

    private var bulkActionBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    let allIDs = Set(items.map(\.id))
                    if selectedIDs == allIDs {
                        selectedIDs.removeAll()
                    } else {
                        selectedIDs = allIDs
                    }
                } label: {
                    let allSelected = selectedIDs.count == items.count
                    Text(allSelected ? "Deselect all" : "Select all")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.brand)
                }
                Spacer()
                Text("\(selectedIDs.count) of \(items.count) selected")
                    .font(.caption)
                    .foregroundStyle(Color.text2)
            }

            HStack(spacing: 8) {
                Button {
                    showBulkAssign = true
                } label: {
                    Label("Assign…", systemImage: "person.2.fill")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.brandSoft, in: .capsule)
                        .foregroundStyle(Color.brand2)
                }
                .disabled(selectedIDs.isEmpty)
                .opacity(selectedIDs.isEmpty ? 0.4 : 1)

                Button {
                    showBulkCategory = true
                } label: {
                    Label("Category…", systemImage: "tag.fill")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.brandSoft, in: .capsule)
                        .foregroundStyle(Color.brand2)
                }
                .disabled(selectedIDs.isEmpty)
                .opacity(selectedIDs.isEmpty ? 0.4 : 1)

                Button {
                    applyBulkSharedByEveryone()
                } label: {
                    Label("Shared", systemImage: "person.3.fill")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.brandSoft, in: .capsule)
                        .foregroundStyle(Color.brand2)
                }
                .disabled(selectedIDs.isEmpty)
                .opacity(selectedIDs.isEmpty ? 0.4 : 1)

                Spacer()
            }
        }
        .padding(10)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private func applyBulkAssignment(_ newIDs: Set<UUID>) {
        for idx in items.indices where selectedIDs.contains(items[idx].id) {
            items[idx].lineItem.assignedToUserIDs = Array(newIDs)
            // Bulk assignment clears any per-person-quantity override so
            // the new shared-by-N split takes effect cleanly.
            items[idx].lineItem.quantityPerUser = nil
        }
    }

    private func applyBulkSharedByEveryone() {
        for idx in items.indices where selectedIDs.contains(items[idx].id) {
            items[idx].lineItem.assignedToUserIDs = []
            items[idx].lineItem.quantityPerUser = nil
        }
    }

    private func applyBulkCategory(_ newCategory: ExpenseCategory) {
        for idx in items.indices where selectedIDs.contains(items[idx].id) {
            items[idx].lineItem.category = newCategory
        }
    }

    @ViewBuilder
    private func lineItemRow(idx: Int) -> some View {
        let nameBinding = Binding(
            get: { items[idx].lineItem.displayName },
            set: { newValue in
                items[idx].lineItem.displayName = newValue
                items[idx].lineItem.itemName = newValue
                items[idx].lineItem.normalizedItemName = newValue
                    .lowercased()
                    .components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                // Editing the name retires the AI cleanup badge for this row.
                items[idx].wasAICleaned = false
            }
        )
        let amountBinding = Binding(
            get: { items[idx].lineItem.amount },
            set: { items[idx].lineItem.amount = $0 }
        )

        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if selectMode {
                    let isSelected = selectedIDs.contains(items[idx].id)
                    Button {
                        if isSelected {
                            selectedIDs.remove(items[idx].id)
                        } else {
                            selectedIDs.insert(items[idx].id)
                        }
                    } label: {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? Color.brand : Color.text3)
                    }
                }
                statusDot(for: items[idx])

                TextField("Item", text: nameBinding)
                    .font(.cardTitle)
                    .foregroundStyle(Color.text1)
                    .textInputAutocapitalization(.words)
                    .disabled(selectMode)

                if items[idx].wasAICleaned {
                    aiBadge(idx: idx)
                }

                Spacer(minLength: 8)

                HStack(spacing: 2) {
                    Text("$").foregroundStyle(Color.text2)
                    TextField("0.00", value: amountBinding,
                              format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                }

                Button {
                    items.remove(at: idx)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(Color.text3)
                }
            }

            HStack(spacing: 8) {
                Button {
                    categoryItemID = items[idx].id
                } label: {
                    let cat = items[idx].lineItem.category
                    HStack(spacing: 6) {
                        Image(systemName: cat?.sfSymbol ?? "tag")
                            .font(.caption)
                        Text(cat?.displayName ?? "Set category")
                            .font(.caption)
                            .lineLimit(1)
                        Image(systemName: "chevron.down").font(.caption2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        cat.map { Color.categoryBg($0) } ?? Color.surface2,
                        in: .capsule
                    )
                    .foregroundStyle(
                        cat.map { Color.categoryFg($0) } ?? Color.text2
                    )
                }

                Button {
                    assigningItemID = items[idx].id
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text(assignmentSummary(for: items[idx]))
                            .font(.caption)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right").font(.caption2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surface2, in: .capsule)
                    .foregroundStyle(Color.text2)
                }
            }
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
        .contextMenu {
            Button {
                quantityItemID = items[idx].id
            } label: {
                Label("Split by quantity", systemImage: "number")
            }
            if items[idx].lineItem.quantityPerUser?.isEmpty == false {
                Button(role: .destructive) {
                    items[idx].lineItem.quantityPerUser = nil
                } label: {
                    Label("Clear quantity split", systemImage: "arrow.uturn.backward")
                }
            }
        }
    }

    @ViewBuilder
    private func statusDot(for item: ReviewItem) -> some View {
        Circle()
            .fill(item.matchedRule == nil ? Color.warn : Color.success)
            .frame(width: 8, height: 8)
            .accessibilityLabel(item.matchedRule == nil ? "New item" : "Known item")
    }

    /// Tappable "AI" pill on items the DeepSeek cleanup renamed. Tap to revert
    /// to the parser's prettified version of the raw OCR.
    @ViewBuilder
    private func aiBadge(idx: Int) -> some View {
        Button {
            let raw = items[idx].lineItem.itemName
            let reverted = ReceiptReviewView.prettifyFallback(raw)
            items[idx].lineItem.displayName = reverted
            items[idx].lineItem.normalizedItemName = reverted
                .lowercased()
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            items[idx].wasAICleaned = false
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "sparkles").font(.caption2)
                Text("AI").font(.caption2.weight(.semibold))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.brandSoft, in: .capsule)
            .foregroundStyle(Color.brand2)
        }
        .accessibilityLabel("Cleaned by AI, tap to revert")
    }

    private static func prettifyFallback(_ raw: String) -> String {
        let lower = raw.lowercased()
        return lower.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    private func assignmentSummary(for item: ReviewItem) -> String {
        if let qpu = item.lineItem.quantityPerUser, !qpu.isEmpty {
            let parts = qpu.compactMap { (uid, units) -> String? in
                guard units > 0,
                      let uuid = UUID(uuidString: uid),
                      let name = members.first(where: { $0.id == UserID(uuid) })?.displayName
                else { return nil }
                return "\(name) \(units)"
            }
            return "By quantity: " + parts.sorted().joined(separator: ", ")
        }
        if item.lineItem.assignedToUserIDs.isEmpty {
            return "Shared by everyone"
        }
        let names = item.lineItem.assignedToUserIDs.compactMap { uuid in
            members.first { $0.id == UserID(uuid) }?.displayName
        }
        return names.joined(separator: ", ")
    }

    private func loadInitial() {
        if items.isEmpty {
            items = draft.items
            descriptionText = draft.merchant ?? ""
            // Pre-select the expense category from the most common line-item
            // category the AI tagged. User can still override on the card.
            let cats = items.compactMap { $0.lineItem.category }
            if !cats.isEmpty {
                let counts = Dictionary(grouping: cats, by: { $0 }).mapValues(\.count)
                if let best = counts.max(by: { $0.value < $1.value })?.key {
                    category = best
                }
            }
        }
    }

    private func commit() async {
        isWorking = true
        defer { isWorking = false }
        await onSave(items, category, descriptionText, date)
    }
}
