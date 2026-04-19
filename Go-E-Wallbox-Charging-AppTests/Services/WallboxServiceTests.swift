import Testing
@testable import Go_E_Wallbox_Charging_App

struct WallboxServiceTests {
    @Test
    func chargingSettingsComputedChargeLimitDividesBatteryNeedByFactor() {
        let chargingSettings = ChargingSettings(
            currentSOCPercent: 20,
            targetSOCPercent: 80,
            batterySizeKWh: 77,
            chargingEnergyDivisor: 1.1
        )

        // (80-20)% of 77 kWh → 46.2 kWh → 46200 Wh from battery perspective, ÷ 1.1
        #expect(chargingSettings.computedChargeLimitWh == 42000)
    }

    @Test
    func chargingSettingsMatchesExampleThirtySevenToEightyWithFactorPointEightFive() {
        let batteryKWh = 15351.0 * 0.85 / 430.0
        let chargingSettings = ChargingSettings(
            currentSOCPercent: 37,
            targetSOCPercent: 80,
            batterySizeKWh: batteryKWh,
            chargingEnergyDivisor: 0.85
        )

        #expect(chargingSettings.computedChargeLimitWh == 15351)
    }

    @Test
    func chargingSettingsYieldsZeroWhenCurrentSOCReachesTarget() {
        let chargingSettings = ChargingSettings(
            currentSOCPercent: 80,
            targetSOCPercent: 80,
            batterySizeKWh: 77,
            chargingEnergyDivisor: 0.85
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
