import Testing
@testable import Go_E_Wallbox_Charging_App

struct WallboxServiceTests {
    @Test
    func chargingSettingsComputedChargeLimitMultipliesBatteryNeedByFactor() {
        let chargingSettings = ChargingSettings(
            currentSOCPercent: 20,
            targetSOCPercent: 80,
            batterySizeKWh: 42,
            chargingEnergyFactor: 0.85
        )

        // (80-20)% of 42 kWh → 25200 Wh × 0.85
        #expect(chargingSettings.computedChargeLimitWh == 21420)
    }

    @Test
    func chargingSettingsMatchesExampleThirtySevenToEightyWithFactorPointEightFive() {
        let chargingSettings = ChargingSettings(
            currentSOCPercent: 37,
            targetSOCPercent: 80,
            batterySizeKWh: 42,
            chargingEnergyFactor: 0.85
        )

        // (80-37)% of 42 kWh → 18060 Wh × 0.85
        #expect(chargingSettings.computedChargeLimitWh == 15351)
    }

    @Test
    func chargingSettingsYieldsZeroWhenCurrentSOCReachesTarget() {
        let chargingSettings = ChargingSettings(
            currentSOCPercent: 80,
            targetSOCPercent: 80,
            batterySizeKWh: 42,
            chargingEnergyFactor: 0.85
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
