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
                    connectionState: .charging,
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
    func synchronizeChargeLimitUpdatesWallboxLimitAndRefreshesStatus() async {
        let appSettings = AppSettings()
        appSettings.targetSOCPercent = 80
        appSettings.batterySizeKWh = 42
        appSettings.chargingEnergyFactor = 0.85

        let service = ApplyChargeLimitServiceMock()
        let viewModel = DashboardViewModel(service: service, settings: appSettings)
        viewModel.currentSOCText = "37"

        await viewModel.synchronizeChargeLimitWithWallbox()

        #expect(service.lastAppliedChargeLimitWh == 15351)
        #expect(viewModel.status.chargeLimitWh == 15351)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @MainActor
    @Test
    func updateTargetSOCDragSnapsToStepAndClampsToRange() {
        let appSettings = AppSettings()
        appSettings.targetSOCPercent = 80
        let service = DashboardServiceMock(result: .success(.placeholder))
        let viewModel = DashboardViewModel(service: service, settings: appSettings)

        viewModel.updateTargetSOCDrag(fraction: 0.63)
        #expect(viewModel.displayedTargetSOCPercent == 65)

        viewModel.updateTargetSOCDrag(fraction: 0.02)
        #expect(viewModel.displayedTargetSOCPercent == appSettings.minSOCPercent)

        viewModel.updateTargetSOCDrag(fraction: 1.2)
        #expect(viewModel.displayedTargetSOCPercent == appSettings.maxSOCPercent)

        // Dragging must not persist until commit.
        #expect(appSettings.targetSOCPercent == 80)
    }

    @MainActor
    @Test
    func commitTargetSOCDragPersistsValueAndSyncsLimit() async {
        let appSettings = AppSettings()
        appSettings.targetSOCPercent = 80
        appSettings.batterySizeKWh = 42
        appSettings.chargingEnergyFactor = 0.85

        let service = ApplyChargeLimitServiceMock()
        let viewModel = DashboardViewModel(service: service, settings: appSettings)
        viewModel.currentSOCText = "37"

        viewModel.updateTargetSOCDrag(fraction: 0.9)
        viewModel.commitTargetSOCDrag()

        #expect(appSettings.targetSOCPercent == 90)
        #expect(viewModel.targetSOCDragValue == nil)
        #expect(viewModel.displayedTargetSOCPercent == 90)

        await viewModel.synchronizeChargeLimitWithWallbox()

        // (90 − 37) % of 42 kWh × 0.85 = 18 921 Wh
        #expect(service.lastAppliedChargeLimitWh == 18921)
    }

    @MainActor
    @Test
    func targetSOCTextInputAppliesValidValuesAndRejectsOutOfRange() {
        let appSettings = AppSettings()
        appSettings.targetSOCPercent = 80
        let service = DashboardServiceMock(result: .success(.placeholder))
        let viewModel = DashboardViewModel(service: service, settings: appSettings)

        viewModel.beginEditingTargetSOC()
        #expect(viewModel.targetSOCText.isEmpty)
        #expect(viewModel.targetSOCFieldIsCleared)

        viewModel.replaceTargetSOCTextWithSanitizedUserInput("85")
        #expect(viewModel.targetSOCValidationError == nil)
        #expect(appSettings.targetSOCPercent == 85)

        viewModel.replaceTargetSOCTextWithSanitizedUserInput("5")
        #expect(viewModel.targetSOCValidationError != nil)
        #expect(appSettings.targetSOCPercent == 85)

        viewModel.endEditingTargetSOC()
        #expect(viewModel.targetSOCValidationError == nil)
        #expect(viewModel.targetSOCText == "85")
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
        connectionState: .waiting,
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
