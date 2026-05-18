import SwiftUI

struct RecurringListView: View {
    @EnvironmentObject private var recurringService: RecurringService

    @State private var showAddSheet = false
    @State private var editingTemplate: RecurringTemplate?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.cardGap) {
                explainerCard

                if recurringService.templates.isEmpty {
                    emptyState
                } else {
                    ForEach(recurringService.templates) { template in
                        Button {
                            editingTemplate = template
                        } label: {
                            RecurringRow(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                }

                addTile
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.vertical, 16)
        }
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle("Recurring")
        .navigationBarTitleDisplayMode(.inline)
        .task { await recurringService.refresh() }
        .sheet(isPresented: $showAddSheet) {
            RecurringEditSheet(mode: .new)
        }
        .sheet(item: $editingTemplate) { template in
            RecurringEditSheet(mode: .edit(template: template))
        }
    }

    private var explainerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Auto-logged bills")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
            Text("Fixed-amount bills get logged automatically each month. Variable bills (like utilities) prompt you to enter the amount when they're due. Splits default to equal across everyone, paid by you. Adjust the expense afterward if needed.")
                .font(.caption)
                .foregroundStyle(Color.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPad)
        .background(Color.brandSoft, in: .rect(cornerRadius: Radius.card))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 32))
                .foregroundStyle(Color.text3)
            Text("No recurring bills yet")
                .font(.cardTitle)
                .foregroundStyle(Color.text1)
            Text("Tap below to set up rent, utilities, or anything that repeats.")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var addTile: some View {
        Button { showAddSheet = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Add a recurring bill").font(.cardLabel)
            }
            .foregroundStyle(Color.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(Color.text3)
            )
        }
    }
}

private struct RecurringRow: View {
    let template: RecurringTemplate

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.tile)
                    .fill(Color.categoryBg(template.category))
                Image(systemName: template.category.sfSymbol)
                    .foregroundStyle(Color.categoryFg(template.category))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(template.description.isEmpty ? template.category.displayName : template.description)
                    .font(.cardTitle)
                    .foregroundStyle(template.isActive ? Color.text1 : Color.text3)
                Text(scheduleSummary)
                    .font(.cardLabel)
                    .foregroundStyle(Color.text2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(amountSummary)
                    .font(.cardTitle)
                    .foregroundStyle(template.isActive ? Color.text1 : Color.text3)
                if !template.isActive {
                    Text("Paused").font(.caption).foregroundStyle(Color.text3)
                } else if template.isDue {
                    Text("Due now").font(.caption.weight(.medium)).foregroundStyle(Color.warn)
                }
            }
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private var amountSummary: String {
        if template.isVariableAmount {
            return "Variable"
        } else {
            return CurrencyFormat.usd(template.amount ?? 0)
        }
    }

    private var scheduleSummary: String {
        let dayLabel = "Day \(template.dayOfMonth)"
        if template.isActive {
            return "\(dayLabel) · next \(template.nextOccurrence.formatted(.dateTime.month(.abbreviated).day()))"
        } else {
            return dayLabel
        }
    }
}
