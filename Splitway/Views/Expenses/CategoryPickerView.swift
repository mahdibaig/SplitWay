import SwiftUI

struct CategoryPickerView: View {
    let selected: ExpenseCategory
    let onPick: (ExpenseCategory) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Button {
                            onPick(category)
                        } label: {
                            tile(category)
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, 12)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func tile(_ category: ExpenseCategory) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.tile)
                    .fill(Color.categoryBg(category))
                Image(systemName: category.sfSymbol)
                    .font(.system(size: 24))
                    .foregroundStyle(Color.categoryFg(category))
            }
            .frame(height: 64)

            Text(category.displayName)
                .font(.cardLabel)
                .foregroundStyle(Color.text1)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(category == selected ? Color.brand : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    CategoryPickerView(selected: .groceries) { _ in }
}
