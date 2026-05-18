import SwiftUI

struct CreateHouseholdView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    private let nameSuggestions = ["Our household", "Home", "Roommates", "Family"]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Name your household")
                    .font(.serifTitle)
                    .foregroundStyle(Color.text1)
                Text("You can change this later.")
                    .foregroundStyle(Color.text2)
            }

            TextField("Household name", text: $viewModel.householdName)
                .textInputAutocapitalization(.words)
                .padding(16)
                .background(Color.surface, in: .rect(cornerRadius: Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card)
                        .stroke(Color.borderSubtle, lineWidth: 1)
                )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(nameSuggestions, id: \.self) { s in
                        Button(s) { viewModel.householdName = s }
                            .font(.cardLabel)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.brandSoft, in: .capsule)
                            .foregroundStyle(Color.brand2)
                    }
                }
            }

            Toggle(isOn: $viewModel.groupsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use groups (couples / families)")
                        .font(.cardTitle)
                        .foregroundStyle(Color.text1)
                    Text("Bills split between groups first, then drill into individuals.")
                        .font(.cardLabel)
                        .foregroundStyle(Color.text2)
                }
            }
            .tint(Color.brand)
            .padding(Spacing.cardPad)
            .background(Color.surface, in: .rect(cornerRadius: Radius.card))

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.cardLabel)
                    .foregroundStyle(Color.warn)
            }

            Spacer()

            Button {
                Task { await viewModel.createHousehold() }
            } label: {
                Group {
                    if viewModel.isWorking {
                        ProgressView()
                            .tint(Color.ctaText)
                    } else {
                        Text("Create household").font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                .foregroundStyle(Color.ctaText)
            }
            .disabled(!viewModel.canCreateHousehold)
            .opacity(viewModel.canCreateHousehold ? 1 : 0.5)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, 48)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.bg.ignoresSafeArea())
    }
}
