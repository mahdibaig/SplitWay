import Foundation

/// Parses Splitwise's CSV export and produces a preview the user can review
/// before committing rows to Core Data. Splitwise's format:
///
///   Date,Description,Category,Cost,Currency,<Name1>,<Name2>,...
///   2024-11-01,November rent,Rent,1500.00,USD,500.00,-500.00,-500.00
///
/// Each person's column shows their NET contribution for that row: positive
/// means they paid more than their share, negative means they owe. The total
/// across people columns sums to zero.
///
/// Splitway can reconstruct an equal split + an approximate paidBy from those
/// values. Non-equal splits in the original Splitwise data are lossy; we
/// document that and let the user adjust after import.
@MainActor
final class SplitwiseImportService: ObservableObject {

    private let expenses: ExpenseRepository
    private let householdService: HouseholdService
    private let membersService: MembersService
    private let expenseService: ExpenseService

    init(
        expenses: ExpenseRepository,
        householdService: HouseholdService,
        membersService: MembersService,
        expenseService: ExpenseService
    ) {
        self.expenses = expenses
        self.householdService = householdService
        self.membersService = membersService
        self.expenseService = expenseService
    }

    // MARK: - Preview

    /// Parses the CSV at `fileURL` into a `Preview`. Does not write anything.
    func parse(fileURL: URL) throws -> Preview {
        let data = try Data(contentsOf: fileURL)
        guard let text = String(data: data, encoding: .utf8) else {
            throw ImportError.unreadable
        }
        let rows = CSVParser.parse(text)
        guard rows.count >= 2 else { throw ImportError.empty }

        let header = rows[0]
        let lower = header.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        guard
            let dateIdx = lower.firstIndex(of: "date"),
            let descIdx = lower.firstIndex(of: "description"),
            let costIdx = lower.firstIndex(of: "cost")
        else {
            throw ImportError.missingColumns
        }
        let categoryIdx = lower.firstIndex(of: "category")
        let currencyIdx = lower.firstIndex(of: "currency")

        // Splitwise puts member names in the columns after the fixed metadata.
        let fixedColumns: Set<String> = ["date", "description", "category", "cost", "currency"]
        var memberColumns: [(name: String, index: Int)] = []
        for (idx, col) in lower.enumerated() {
            if !fixedColumns.contains(col), !col.isEmpty {
                memberColumns.append((name: header[idx].trimmingCharacters(in: .whitespaces), index: idx))
            }
        }

        guard !memberColumns.isEmpty else { throw ImportError.noMembers }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let altFormatter = DateFormatter()
        altFormatter.dateFormat = "yyyy-MM-dd"
        altFormatter.locale = Locale(identifier: "en_US_POSIX")

        var parsedRows: [ParsedRow] = []
        var rowErrors: [String] = []

        for (rowIdx, row) in rows.dropFirst().enumerated() {
            guard row.count > max(dateIdx, descIdx, costIdx) else { continue }
            let rawCost = row[costIdx].trimmingCharacters(in: .whitespaces)
            guard let cost = Decimal(string: rawCost), cost > 0 else {
                // Total row at the bottom is often empty for Cost. Skip silently.
                continue
            }

            let rawDate = row[dateIdx].trimmingCharacters(in: .whitespaces)
            let date = dateFormatter.date(from: rawDate)
                ?? altFormatter.date(from: rawDate)
                ?? Date()

            let description = row[descIdx].trimmingCharacters(in: .whitespaces)
            let categoryRaw = categoryIdx.flatMap { row.indices.contains($0) ? row[$0] : nil }
                ?? ""
            let currency = currencyIdx.flatMap { row.indices.contains($0) ? row[$0] : nil }
                ?? "USD"

            // Per-person nets. A row's nets sum to ~0; non-zero entries are participants.
            var nets: [(name: String, net: Decimal)] = []
            for col in memberColumns where row.indices.contains(col.index) {
                let raw = row[col.index].trimmingCharacters(in: .whitespaces)
                let value = Decimal(string: raw) ?? .zero
                if value != .zero {
                    nets.append((name: col.name, net: value))
                }
            }

            if nets.isEmpty {
                rowErrors.append("Row \(rowIdx + 2): no participants. Skipped.")
                continue
            }

            parsedRows.append(ParsedRow(
                date: date,
                description: description.isEmpty ? "Imported expense" : description,
                splitwiseCategory: categoryRaw,
                category: mapCategory(categoryRaw),
                cost: cost,
                currency: currency.isEmpty ? "USD" : currency,
                participantNets: nets
            ))
        }

        let uniqueNames = Array(Set(parsedRows.flatMap { $0.participantNets.map(\.name) }))
            .sorted()

        // Best-effort match against current household members.
        let active = membersService.members.filter { !$0.isArchived }
        var matches: [String: UserID] = [:]
        for name in uniqueNames {
            if let match = bestMatch(for: name, in: active) {
                matches[name] = match.id
            }
        }

        return Preview(
            rows: parsedRows,
            splitwiseMemberNames: uniqueNames,
            matches: matches,
            warnings: rowErrors
        )
    }

    // MARK: - Commit

    /// Inserts all matched rows as Splitway expenses. Skips rows where any
    /// participant isn't matched to a Splitway member.
    @discardableResult
    func commit(preview: Preview) async throws -> CommitResult {
        guard
            let householdID = householdService.currentHousehold?.id,
            let meID = householdService.currentMember?.id
        else { throw ImportError.noHousehold }

        var inserted = 0
        var skipped = 0

        for row in preview.rows {
            let participantIDs: [UUID] = row.participantNets.compactMap { entry in
                preview.matches[entry.name]?.raw
            }
            guard participantIDs.count == row.participantNets.count else {
                skipped += 1
                continue
            }

            // Reconstruct paidBy: for each participant, paid = max(0, net) +
            // their equal share. (Splitwise CSV doesn't expose individual
            // shares, so we assume equal among participants. Users can edit.)
            let perShare = row.cost / Decimal(participantIDs.count)
            var paidBy: [PaidByEntry] = []
            for entry in row.participantNets {
                guard let userID = preview.matches[entry.name] else { continue }
                let paid = entry.net + perShare
                if paid > 0 {
                    paidBy.append(PaidByEntry(userID: userID.raw, amount: paid))
                }
            }

            // If no one paid (all-negative row, shouldn't happen but guard
            // anyway) fall back to logging it under the importing user.
            if paidBy.isEmpty {
                paidBy = [PaidByEntry(userID: meID.raw, amount: row.cost)]
            }

            let splitRule = SplitRule(
                type: .equal,
                participantIDs: participantIDs,
                participantValues: [],
                paidBy: paidBy,
                participantsAreGroups: false
            )

            let now = Date()
            let expense = Expense(
                id: UUID(),
                householdID: householdID,
                loggedByUserID: meID,
                amount: row.cost,
                currency: row.currency,
                category: row.category,
                description: row.description,
                merchant: nil,
                date: row.date,
                createdAt: now,
                updatedAt: now,
                splitRule: splitRule,
                editHistory: [],
                isSettled: false,
                notes: "Imported from Splitwise",
                isRecurringInstance: false,
                recurringTemplateID: nil,
                receiptImageData: nil,
                lineItems: [],
                softDeletedAt: nil
            )

            do {
                try await expenses.create(expense)
                inserted += 1
            } catch {
                AppLog.data.error("Import row failed: \(error.localizedDescription, privacy: .public)")
                skipped += 1
            }
        }

        await expenseService.refresh()
        return CommitResult(inserted: inserted, skipped: skipped)
    }

    // MARK: - Internals

    /// Splitwise's free-form category strings map onto Splitway's fixed list.
    /// Anything we don't recognize falls back to "other".
    private func mapCategory(_ raw: String) -> ExpenseCategory {
        let s = raw.lowercased()
        if s.contains("rent") || s.contains("mortgage") { return .rent }
        if s.contains("util") || s.contains("electric") || s.contains("gas")
            || s.contains("water") || s.contains("internet") || s.contains("phone") {
            return .utilities
        }
        if s.contains("groc") || s.contains("food shop") { return .groceries }
        if s.contains("dining") || s.contains("restaur") || s.contains("food and drink")
            || s.contains("eat") { return .diningOut }
        if s.contains("transport") || s.contains("uber") || s.contains("lyft")
            || s.contains("taxi") || s.contains("gasoline") || s.contains("car") {
            return .transportation
        }
        if s.contains("enter") || s.contains("movie") || s.contains("game")
            || s.contains("music") || s.contains("concert") { return .entertainment }
        if s.contains("household") || s.contains("home") || s.contains("supplies")
            || s.contains("cleaning") { return .householdSupplies }
        if s.contains("personal") || s.contains("beauty") || s.contains("hygiene") {
            return .personalCare
        }
        if s.contains("health") || s.contains("medical") || s.contains("doctor")
            || s.contains("pharma") { return .healthcare }
        return .other
    }

    /// Case-insensitive exact match, then substring match.
    private func bestMatch(for name: String, in members: [HouseholdMember]) -> HouseholdMember? {
        let n = name.lowercased()
        if let exact = members.first(where: { $0.displayName.lowercased() == n }) {
            return exact
        }
        if let prefix = members.first(where: {
            let mname = $0.displayName.lowercased()
            return mname.hasPrefix(n) || n.hasPrefix(mname)
        }) {
            return prefix
        }
        return nil
    }

    // MARK: - Types

    struct Preview {
        var rows: [ParsedRow]
        var splitwiseMemberNames: [String]
        var matches: [String: UserID]
        var warnings: [String]

        var rowCount: Int { rows.count }
        var totalAmount: Decimal { rows.reduce(.zero) { $0 + $1.cost } }
        var unmatched: [String] {
            splitwiseMemberNames.filter { matches[$0] == nil }
        }
        var dateRange: (start: Date, end: Date)? {
            let dates = rows.map(\.date).sorted()
            guard let first = dates.first, let last = dates.last else { return nil }
            return (first, last)
        }
    }

    struct ParsedRow: Identifiable {
        let id = UUID()
        let date: Date
        let description: String
        let splitwiseCategory: String
        let category: ExpenseCategory
        let cost: Decimal
        let currency: String
        let participantNets: [(name: String, net: Decimal)]
    }

    struct CommitResult {
        let inserted: Int
        let skipped: Int
    }

    enum ImportError: Error, LocalizedError {
        case unreadable
        case empty
        case missingColumns
        case noMembers
        case noHousehold

        var errorDescription: String? {
            switch self {
            case .unreadable:       return "Couldn't read that file as text."
            case .empty:            return "The CSV has no rows."
            case .missingColumns:   return "Doesn't look like a Splitwise export. Expected Date, Description, and Cost columns."
            case .noMembers:        return "No member columns found in the CSV."
            case .noHousehold:      return "Create or join a household first."
            }
        }
    }
}

// MARK: - CSV parser (RFC 4180 subset)

/// Splits CSV text into rows of fields. Handles quoted fields with commas
/// and escaped quotes inside them. No external dependency.
enum CSVParser {
    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var current: [String] = []
        var field = ""
        var inQuotes = false
        var i = text.startIndex

        while i < text.endIndex {
            let c = text[i]
            if inQuotes {
                if c == "\"" {
                    let next = text.index(after: i)
                    if next < text.endIndex, text[next] == "\"" {
                        // Escaped double quote inside a quoted field.
                        field.append("\"")
                        i = text.index(after: next)
                        continue
                    }
                    inQuotes = false
                } else {
                    field.append(c)
                }
            } else {
                switch c {
                case "\"":
                    inQuotes = true
                case ",":
                    current.append(field)
                    field = ""
                case "\n":
                    current.append(field)
                    rows.append(current)
                    current = []
                    field = ""
                case "\r":
                    break  // ignore; we'll catch \n
                default:
                    field.append(c)
                }
            }
            i = text.index(after: i)
        }
        // Trailing line without newline.
        if !field.isEmpty || !current.isEmpty {
            current.append(field)
            rows.append(current)
        }
        return rows
    }
}
