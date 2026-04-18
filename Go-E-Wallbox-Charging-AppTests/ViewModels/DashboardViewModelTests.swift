import Testing
@testable import Go_E_Wallbox_Charging_App

struct DashboardViewModelTests {
    @MainActor
    @Test
    func refreshStatusUpdatesStatusOnSuccess() async {
        let service = DashboardServiceMock(
            result: .success(
                WallboxStatus(
                    isConnected: true,
                    connectionState: .idle,
                    chargingPowerW: 11000,
                    energyPerDayWh: 23000,
                    chargeLimitWh: 0
                )
            )
        )
        let viewModel = DashboardViewModel(service: service, settings: AppSettings())

        await viewModel.refreshStatus()

        #expect(viewModel.status.isConnected)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @MainActor
    @Test
    func applyChargeLimitUpdatesWallboxLimitAndRefreshesStatus() async {
        let appSettings = AppSettings()
        appSettings.targetSOCPercent = 80
        appSettings.batterySizeKWh = 77
        appSettings.chargingLossFactor = 1.1

        let service = ApplyChargeLimitServiceMock()
        let viewModel = DashboardViewModel(service: service, settings: appSettings)
        viewModel.currentSOCPercent = 20

        await viewModel.applyChargeLimit()

        #expect(service.lastAppliedChargeLimitWh == 50820)
        #expect(viewModel.status.chargeLimitWh == 50820)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }
}

private struct DashboardServiceMock: WallboxServiceProtocol {
    let result: Result<WallboxStatus, Error>

    func fetchStatus() async throws -> WallboxStatus {
        try result.get()
    }

    func updateChargingSettings(_: ChargingSettings) async throws {}
}

private final class ApplyChargeLimitServiceMock: WallboxServiceProtocol {
    private(set) var lastAppliedChargeLimitWh: Int?
    private var status = WallboxStatus(
        isConnected: true,
        connectionState: .idle,
        chargingPowerW: 0,
        energyPerDayWh: 0,
        chargeLimitWh: 0
    )

    func fetchStatus() async throws -> WallboxStatus {
        status
    }

    func updateChargingSettings(_ chargingSettings: ChargingSettings) async throws {
        let limit = chargingSettings.computedChargeLimitWh
        lastAppliedChargeLimitWh = limit
        status = WallboxStatus(
            isConnected: status.isConnected,
            connectionState: status.connectionState,
            chargingPowerW: status.chargingPowerW,
            energyPerDayWh: status.energyPerDayWh,
            chargeLimitWh: limit
        )
    }
}
