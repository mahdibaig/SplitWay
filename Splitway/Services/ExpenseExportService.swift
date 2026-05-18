import Foundation

/// Builds a CSV of the household's expenses. One row per expense with each
/// active member's computed share in its own column, so the file is both
/// human-readable and round-trippable back through the Splitwise-style
/// importer. Pro feature (gated by `.csvImportExport`).
@MainActor
final class ExpenseExportService: ObservableObject {

    private let expenseService: ExpenseService
    private let membersService: MembersService
    private let householdService: HouseholdService

    init(
        expenseService: ExpenseService,
        membersService: MembersService,
        householdService: HouseholdService
    ) {
        self.expenseService = expenseService
        self.membersService = membersService
        self.householdService = householdService
    }

    var expenseCount: Int {
        expenseService.expensesList.filter { $0.softDeletedAt == nil }.count
    }

    /// Writes the CSV to a temp file and returns its URL (for ShareLink).
    func exportFile() async -> URL? {
        await expenseService.refresh()
        await membersService.refresh()

        let members = membersService.members.filter { !$0.isArchived }
        let groupMembership = membersService.groupMembership
        let expenses = expenseService.expensesList
            .filter { $0.softDeletedAt == nil }
            .sorted { $0.date < $1.date }

        var header = ["Date", "Description", "Category", "Cost", "Currency", "Paid by", "Split"]
        header.append(contentsOf: members.map(\.displayName))
        header.append("Notes")

        var lines = [row(header)]

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        dateFmt.locale = Locale(identifier: "en_US_POSIX")

        for expense in expenses {
            let shares = SplitResolver.resolveUserShares(
                rule: expense.splitRule,
                total: expense.amount,
                groupMembership: groupMembership
            )
            let payerNames = expense.splitRule.paidBy.compactMap { entry -> String? in
                members.first { $0.id == UserID(entry.userID) }?.displayName
            }

            var fields: [String] = [
                dateFmt.string(from: expense.date),
                expense.description.isEmpty ? expense.category.displayName : expense.description,
                expense.category.displayName,
                decimalString(expense.amount),
                expense.currency,
                payerNames.joined(separator: " + "),
                expense.splitRule.type.displayName
            ]
            for member in members {
                let share = shares[member.id] ?? 0
                fields.append(share == 0 ? "" : decimalString(share))
            }
            fields.append(expense.notes ?? "")
            lines.append(row(fields))
        }

        let csv = lines.joined(separator: "\n")
        let name = "Splitway-\(householdService.currentHousehold?.name ?? "export")"
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "_")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name).csv")
        do {
            try csv.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            AppLog.data.error("CSV export write failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - CSV helpers

    private func decimalString(_ d: Decimal) -> String {
        NSDecimalNumber(decimal: d).stringValue
    }

    /// RFC 4180: quote a field if it contains comma, quote, or newline;
    /// double any internal quotes.
    private func row(_ fields: [String]) -> String {
        fields.map { field in
            if field.contains(",") || field.contains("\"") || field.contains("\n") {
                return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
            }
            return field
        }.joined(separator: ",")
    }
}
