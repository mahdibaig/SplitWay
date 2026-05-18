import SwiftUI

enum OnboardingStep {
    case welcome
    case displayName
    case createOrJoin
    case createHousehold
    case joinHousehold
}

struct OnboardingFlow: View {
    @EnvironmentObject private var householdService: HouseholdService
    @StateObject private var vm: VMHolder = VMHolder()
    @State private var step: OnboardingStep = .welcome

    var body: some View {
        Group {
            if let viewModel = vm.viewModel {
                content(viewModel: viewModel)
            } else {
                Color.onboardingBg.ignoresSafeArea()
            }
        }
        .onAppear { vm.attach(householdService: householdService) }
        // Onboarding is always the tan/light experience (matches the video),
        // regardless of the app-wide appearance setting, so text stays readable.
        .environment(\.colorScheme, .light)
    }

    @ViewBuilder
    private func content(viewModel: OnboardingViewModel) -> some View {
        switch step {
        case .welcome:
            WelcomeView { step = .displayName }

        case .displayName:
            DisplayNameView(viewModel: viewModel) {
                step = .createOrJoin
            }

        case .createOrJoin:
            CreateOrJoinView(
                onCreate: { step = .createHousehold },
                onJoin: { step = .joinHousehold }
            )

        case .createHousehold:
            CreateHouseholdView(viewModel: viewModel)

        case .joinHousehold:
            JoinHouseholdView(viewModel: viewModel) {
                step = .createOrJoin
            }
        }
    }
}

/// Wrapper so we can build the view model lazily (it depends on the env-injected
/// HouseholdService, which isn't available at @StateObject init time).
@MainActor
private final class VMHolder: ObservableObject {
    @Published var viewModel: OnboardingViewModel?

    func attach(householdService: HouseholdService) {
        if viewModel == nil {
            viewModel = OnboardingViewModel(householdService: householdService)
        }
    }
}
