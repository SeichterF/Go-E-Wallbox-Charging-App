import Testing
@testable import Go_E_Wallbox_Charging_App

struct WallboxServiceTests {
    @Test
    func fetchStatusReturnsPlaceholderFromClient() async throws {
        let settings = AppSettings()
        let service = WallboxService(
            apiClient: WallboxAPIClient(settings: settings),
            settings: settings
        )

        let status = try await service.fetchStatus()

        #expect(status == .placeholder)
    }
}
