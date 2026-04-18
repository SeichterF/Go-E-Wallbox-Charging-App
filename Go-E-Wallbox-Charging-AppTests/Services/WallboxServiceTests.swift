import Testing
@testable import Go_E_Wallbox_Charging_App

struct WallboxServiceTests {
    @Test
    func chargingSettingsComputedChargeLimitMatchesShortcutExample() {
        let chargingSettings = ChargingSettings(
            currentSOCPercent: 20,
            targetSOCPercent: 80,
            batterySizeKWh: 77,
            chargingLossFactor: 1.1
        )

        #expect(chargingSettings.computedChargeLimitWh == 50820)
    }

    @Test
    func chargingSettingsYieldsZeroWhenCurrentSOCReachesTarget() {
        let chargingSettings = ChargingSettings(
            currentSOCPercent: 80,
            targetSOCPercent: 80,
            batterySizeKWh: 77,
            chargingLossFactor: 1.1
        )

        #expect(chargingSettings.computedChargeLimitWh == 0)
    }

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
