import SwiftUI

@main
struct Go_E_Wallbox_Charging_AppApp: App {
    @State private var appSettings = AppSettings()
    @State private var wallboxService: WallboxServiceProtocol

    init() {
        let settings = AppSettings()
        _appSettings = State(initialValue: settings)
        _wallboxService = State(initialValue: WallboxService(
            apiClient: WallboxAPIClient(settings: settings),
            settings: settings
        ))
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(
                dashboardViewModel: DashboardViewModel(service: wallboxService),
                settingsViewModel: SettingsViewModel(settings: appSettings)
            )
        }
    }
}
