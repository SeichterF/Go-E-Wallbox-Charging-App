import SwiftUI

struct MainTabView: View {
    @State private var dashboardViewModel: DashboardViewModel
    @State private var settingsViewModel: SettingsViewModel

    init(dashboardViewModel: DashboardViewModel, settingsViewModel: SettingsViewModel) {
        _dashboardViewModel = State(initialValue: dashboardViewModel)
        _settingsViewModel = State(initialValue: settingsViewModel)
    }

    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem {
                    Label(AppConstants.UI.dashboardTitle, systemImage: "bolt.car")
                }

            SettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Label(AppConstants.UI.settingsTitle, systemImage: "gearshape")
                }
        }
    }
}
