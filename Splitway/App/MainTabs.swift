import SwiftUI

enum AppTab: Hashable {
    case home
    case expenses
    case reports
    case assistant
    case settings
}

struct MainTabs: View {
    @State private var selectedTab: AppTab = .home
    @State private var presentAddExpense = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(AppTab.home)
                    .tabItem { Label("Home", systemImage: "house.fill") }

                ExpensesListView()
                    .tag(AppTab.expenses)
                    .tabItem { Label("Expenses", systemImage: "list.bullet.rectangle") }

                ReportsView()
                    .tag(AppTab.reports)
                    .tabItem { Label("Reports", systemImage: "chart.pie.fill") }

                ProGate(feature: .aiAssistant) { AssistantView() }
                    .tag(AppTab.assistant)
                    .tabItem { Label("Assistant", systemImage: "bubble.left.and.bubble.right.fill") }

                SettingsView()
                    .tag(AppTab.settings)
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            .tint(Color.brand)

            if selectedTab == .home || selectedTab == .expenses {
                fab
                    .padding(.trailing, 18)
                    .padding(.bottom, 100)  // clears tab bar (49pt) + home indicator safe area (~34pt)
            }
        }
        .sheet(isPresented: $presentAddExpense) {
            AddExpenseView()
        }
    }

    private var fab: some View {
        Button {
            presentAddExpense = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .frame(width: 56, height: 56)
                .background(Color.cta, in: .circle)
                .foregroundStyle(Color.ctaText)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        }
        .accessibilityLabel("Add expense")
    }
}

#Preview {
    let services = ServiceContainer.preview()
    return MainTabs()
        .environmentObject(services)
        .environmentObject(services.householdService)
        .environmentObject(services.membersService)
        .environmentObject(services.expenseService)
        .environmentObject(services.settlementService)
        .environmentObject(services.groupService)
}
