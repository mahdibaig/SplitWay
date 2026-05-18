import SwiftUI

/// Per-person quantity split for a single receipt line. The Splitwise gap:
/// "Alice had 2 beers, Bob had 1." Cost is shared proportionally to units.
/// Returns a map of user UUID string -> units (zeros dropped); empty map
/// means "no quantity split, fall back to equal assignment".
struct LineItemQuantitySheet: View {
    let itemName: String
    let amount: Decimal
    let members: [HouseholdMember]
    let onSave: ([String: Int]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var units: [UUID: Int]

    init(
        itemName: String,
        amount: Decimal,
        members: [HouseholdMember],
        quantityPerUser: [String: Int],
        onSave: @escaping ([String: Int]) -> Void
    ) {
        self.itemName = itemName
        self.amount = amount
        self.members = members
        self.onSave = onSave
        var seed: [UUID: Int] = [:]
        for (k, v) in quantityPerUser {
            if let uuid = UUID(uuidString: k) { seed[uuid] = v }
        }
        self._units = State(initialValue: seed)
    }

    private var totalUnits: Int { units.values.reduce(0, +) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(members.filter { !$0.isArchived }) { member in
                        row(for: member)
                    }
                } header: {
                    Text(itemName.isEmpty ? "Item" : itemName)
                } footer: {
                    if totalUnits == 0 {
                        Text("Set how many units each person had. Cost is split proportionally. Leave all at 0 to cancel the quantity split.")
                    } else {
                        Text("\(totalUnits) unit\(totalUnits == 1 ? "" : "s") total, \(CurrencyFormat.usd(amount)) split proportionally.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Split by quantity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        var map: [String: Int] = [:]
                        for (uuid, u) in units where u > 0 {
                            map[uuid.uuidString] = u
                        }
                        onSave(map)
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func row(for member: HouseholdMember) -> some View {
        let count = units[member.id.raw] ?? 0
        let share: Decimal = totalUnits > 0
            ? amount * Decimal(count) / Decimal(totalUnits)
            : 0
        HStack(spacing: 12) {
            MemberAvatar(member: member, size: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text(member.displayName).foregroundStyle(Color.text1)
                if count > 0 {
                    Text(CurrencyFormat.usd(share))
                        .font(.caption)
                        .foregroundStyle(Color.text2)
                }
            }
            Spacer()
            Stepper(
                value: Binding(
                    get: { units[member.id.raw] ?? 0 },
                    set: { units[member.id.raw] = max(0, $0) }
                ),
                in: 0...99
            ) {
                Text("\(count)")
                    .font(.cardTitle)
                    .foregroundStyle(Color.text1)
                    .frame(minWidth: 24)
            }
            .labelsHidden()
        }
    }
}
