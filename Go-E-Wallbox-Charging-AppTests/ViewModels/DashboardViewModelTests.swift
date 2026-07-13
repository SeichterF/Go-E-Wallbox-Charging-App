import Foundation
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
                    chargeLimitWh: 0,
                    forceState: 0,
                    activeTransaction: -1,
                    availableCards: []
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
    func isForceChargingReflectsActiveChargingSessionEvenWithoutForceState() async {
        // A session started via a physical RFID card leaves `frc` at 0 even while `car` reports charging.
        let service = DashboardServiceMock(
            result: .success(
                WallboxStatus(
                    isConnected: true,
                    connectionState: .charging,
                    chargingPowerW: 11000,
                    energyPerDayWh: 5000,
                    chargeLimitWh: 0,
                    forceState: 0,
                    activeTransaction: -1,
                    availableCards: []
                )
            )
        )
        let viewModel = DashboardViewModel(service: service, settings: AppSettings())

        await viewModel.refreshStatus()

        #expect(viewModel.isForceCharging)
        #expect(viewModel.canStartCharging == false)
    }

    @MainActor
    @Test
    func refreshStatusSurfacesErrorMessageOnFailure() async {
        let service = DashboardServiceMock(result: .failure(URLError(.badServerResponse)))
        let viewModel = DashboardViewModel(service: service, settings: AppSettings())

        await viewModel.refreshStatus()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.status == .placeholder)
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
    func synchronizeChargeLimitSurfacesErrorAndRetriesAfterFailure() async {
        let service = ApplyChargeLimitServiceMock()
        service.updateError = URLError(.notConnectedToInternet)
        let viewModel = DashboardViewModel(service: service, settings: AppSettings())
        viewModel.currentSOCText = "37"

        await viewModel.synchronizeChargeLimitWithWallbox()

        #expect(viewModel.errorMessage != nil)
        #expect(service.updateCallCount == 1)

        // A failed sync must not be recorded as synced — the next call retries.
        service.updateError = nil
        await viewModel.synchronizeChargeLimitWithWallbox()

        #expect(service.updateCallCount == 2)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test
    func synchronizeChargeLimitSkipsWallboxCallWhenNothingChanged() async {
        let service = ApplyChargeLimitServiceMock()
        let viewModel = DashboardViewModel(service: service, settings: AppSettings())
        viewModel.currentSOCText = "37"

        await viewModel.synchronizeChargeLimitWithWallbox()
        await viewModel.synchronizeChargeLimitWithWallbox()

        #expect(service.updateCallCount == 1)

        viewModel.currentSOCText = "40"
        await viewModel.synchronizeChargeLimitWithWallbox()

        #expect(service.updateCallCount == 2)
    }

    @MainActor
    @Test
    func firstRefreshInitializesCurrentSOCFromWallboxChargeLimit() async {
        let appSettings = AppSettings()
        appSettings.targetSOCPercent = 80
        appSettings.batterySizeKWh = 42
        appSettings.chargingEnergyFactor = 0.85

        // dwo 15351 Wh at 42 kWh × 0.85 implies 43 SOC points → current SOC 80 − 43 = 37.
        let service = ApplyChargeLimitServiceMock(
            initialStatus: WallboxStatus(
                isConnected: true,
                connectionState: .waiting,
                chargingPowerW: 0,
                energyPerDayWh: 0,
                chargeLimitWh: 15351,
                forceState: 0,
                activeTransaction: -1,
                availableCards: []
            )
        )
        let viewModel = DashboardViewModel(service: service, settings: appSettings)

        await viewModel.refreshStatus()
        #expect(viewModel.currentSOCText == "37")

        // The initialized value counts as synced — no redundant wallbox write.
        await viewModel.synchronizeChargeLimitWithWallbox()
        #expect(service.updateCallCount == 0)

        // Only the first refresh initializes; user input survives later refreshes.
        viewModel.currentSOCText = "50"
        await viewModel.refreshStatus()
        #expect(viewModel.currentSOCText == "50")
    }

    @MainActor
    @Test
    func firstRefreshWithoutChargeLimitLeavesCurrentSOCUntouched() async {
        let service = ApplyChargeLimitServiceMock()
        let viewModel = DashboardViewModel(service: service, settings: AppSettings())

        await viewModel.refreshStatus()

        #expect(viewModel.currentSOCText == "0")
    }

    @MainActor
    @Test
    func currentSOCInputSanitizesDigitsAndValidatesRange() {
        let service = DashboardServiceMock(result: .success(.placeholder))
        let viewModel = DashboardViewModel(service: service, settings: AppSettings())

        viewModel.replaceCurrentSOCTextWithSanitizedUserInput("1a5")
        #expect(viewModel.currentSOCText == "15")
        #expect(viewModel.socValidationError == nil)

        viewModel.replaceCurrentSOCTextWithSanitizedUserInput("150")
        #expect(viewModel.socValidationError != nil)
        #expect(viewModel.parsedCurrentSOCPercent == 100)

        viewModel.replaceCurrentSOCTextWithSanitizedUserInput("")
        #expect(viewModel.currentSOCText.isEmpty)
        #expect(viewModel.socFieldIsCleared)
        #expect(viewModel.parsedCurrentSOCPercent == 0)

        viewModel.replaceCurrentSOCTextWithSanitizedUserInput("007")
        #expect(viewModel.currentSOCText == "7")
    }

    @MainActor
    @Test
    func beginAndEndEditingRestorePreviousValueWhenFieldStaysEmpty() {
        let service = DashboardServiceMock(result: .success(.placeholder))
        let viewModel = DashboardViewModel(service: service, settings: AppSettings())
        viewModel.currentSOCText = "37"

        viewModel.beginEditing()
        #expect(viewModel.currentSOCText.isEmpty)
        #expect(viewModel.socFieldIsCleared)

        viewModel.endEditing()
        #expect(viewModel.currentSOCText == "37")
        #expect(viewModel.socFieldIsCleared == false)

        viewModel.beginEditing()
        viewModel.replaceCurrentSOCTextWithSanitizedUserInput("55")
        viewModel.endEditing()
        #expect(viewModel.currentSOCText == "55")
    }

    @MainActor
    @Test
    func updateCurrentSOCDragSnapsToStepAndClampsToRange() {
        let service = DashboardServiceMock(result: .success(.placeholder))
        let viewModel = DashboardViewModel(service: service, settings: AppSettings())

        viewModel.updateCurrentSOCDrag(fraction: 0.63)
        #expect(viewModel.currentSOCDragValue == 65)
        #expect(viewModel.displayedCurrentSOCPercent == 65)
        #expect(viewModel.currentSOCText == "65")

        viewModel.updateCurrentSOCDrag(fraction: -0.1)
        #expect(viewModel.displayedCurrentSOCPercent == 0)

        viewModel.updateCurrentSOCDrag(fraction: 1.2)
        #expect(viewModel.displayedCurrentSOCPercent == 100)

        viewModel.commitCurrentSOCDrag()
        #expect(viewModel.currentSOCDragValue == nil)
        #expect(viewModel.currentSOCText == "100")
    }

    @MainActor
    @Test
    func calculatedCurrentSOCPercentAddsChargedEnergyToParsedSOC() async {
        let appSettings = AppSettings()
        appSettings.batterySizeKWh = 42
        appSettings.chargingEnergyFactor = 0.85

        // 10 kWh charged × 0.85 = 8.5 kWh stored → 8.5/42 ≈ 20 SOC points.
        let service = DashboardServiceMock(
            result: .success(
                WallboxStatus(
                    isConnected: true,
                    connectionState: .charging,
                    chargingPowerW: 11000,
                    energyPerDayWh: 10000,
                    chargeLimitWh: 0,
                    forceState: 0,
                    activeTransaction: -1,
                    availableCards: []
                )
            )
        )
        let viewModel = DashboardViewModel(service: service, settings: appSettings)
        viewModel.currentSOCText = "37"

        await viewModel.refreshStatus()

        #expect(viewModel.calculatedCurrentSOCPercent == 57)
    }

    @MainActor
    @Test
    func calculatedCurrentSOCPercentClampsToHundredAndHandlesZeroBattery() async {
        let appSettings = AppSettings()
        appSettings.batterySizeKWh = 42
        appSettings.chargingEnergyFactor = 0.85

        let service = DashboardServiceMock(
            result: .success(
                WallboxStatus(
                    isConnected: true,
                    connectionState: .charging,
                    chargingPowerW: 11000,
                    energyPerDayWh: 200_000,
                    chargeLimitWh: 0,
                    forceState: 0,
                    activeTransaction: -1,
                    availableCards: []
                )
            )
        )
        let viewModel = DashboardViewModel(service: service, settings: appSettings)
        viewModel.currentSOCText = "37"

        await viewModel.refreshStatus()
        #expect(viewModel.calculatedCurrentSOCPercent == 100)

        appSettings.batterySizeKWh = 0
        #expect(viewModel.calculatedCurrentSOCPercent == 37)
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

    @MainActor
    @Test
    func startChargingFallsBackToFirstCardWhenSelectedCardNoLongerExists() async {
        let appSettings = AppSettings()
        appSettings.selectedCardIndex = 3 // stale index, no longer reported by the wallbox
        let service = StartChargingServiceMock(status: makeConnectedStatus(cards: [RFIDCard(id: 0, name: "Alice")]))
        let viewModel = DashboardViewModel(service: service, settings: appSettings)
        await viewModel.refreshStatus()

        await viewModel.startCharging()

        #expect(service.lastStartedCardIndex == 0)
    }

    @MainActor
    @Test
    func startChargingDefaultsToFirstCardWhenNothingSelected() async {
        let appSettings = AppSettings() // default selectedCardIndex == -2 (auto)
        let service = StartChargingServiceMock(
            status: makeConnectedStatus(cards: [RFIDCard(id: 0, name: "Alice"), RFIDCard(id: 1, name: "Bob")])
        )
        let viewModel = DashboardViewModel(service: service, settings: appSettings)
        await viewModel.refreshStatus()

        await viewModel.startCharging()

        #expect(service.lastStartedCardIndex == 0)
    }

    @MainActor
    @Test
    func startChargingUsesNoUserWhenExplicitlySelected() async {
        let appSettings = AppSettings()
        appSettings.selectedCardIndex = -1 // explicit "no user"
        let service = StartChargingServiceMock(status: makeConnectedStatus(cards: [RFIDCard(id: 0, name: "Alice")]))
        let viewModel = DashboardViewModel(service: service, settings: appSettings)
        await viewModel.refreshStatus()

        await viewModel.startCharging()

        #expect(service.lastStartedCardIndex == -1)
    }

    @MainActor
    @Test
    func startChargingUsesSelectedCardIndexWhenValid() async {
        let appSettings = AppSettings()
        appSettings.selectedCardIndex = 0
        let service = StartChargingServiceMock(status: makeConnectedStatus(cards: [RFIDCard(id: 0, name: "Alice")]))
        let viewModel = DashboardViewModel(service: service, settings: appSettings)
        await viewModel.refreshStatus()

        await viewModel.startCharging()

        #expect(service.lastStartedCardIndex == 0)
    }

    @MainActor
    @Test
    func startChargingEntersFastBurstPolling() async {
        let appSettings = AppSettings()
        appSettings.pollingIntervalSeconds = 15
        let service = StartChargingServiceMock(status: makeConnectedStatus(cards: []))
        let viewModel = DashboardViewModel(service: service, settings: appSettings)

        #expect(viewModel.currentPollingIntervalSeconds == 15)

        await viewModel.startCharging()
        #expect(viewModel.currentPollingIntervalSeconds == 1)
    }

    @MainActor
    @Test
    func stopChargingEntersFastBurstPolling() async {
        let appSettings = AppSettings()
        appSettings.pollingIntervalSeconds = 15
        let service = StartChargingServiceMock(status: makeConnectedStatus(cards: []))
        let viewModel = DashboardViewModel(service: service, settings: appSettings)

        await viewModel.stopCharging()
        #expect(viewModel.currentPollingIntervalSeconds == 1)
    }
}

private func makeConnectedStatus(cards: [RFIDCard]) -> WallboxStatus {
    WallboxStatus(
        isConnected: true,
        connectionState: .waiting,
        chargingPowerW: 0,
        energyPerDayWh: 0,
        chargeLimitWh: 0,
        forceState: 0,
        activeTransaction: -1,
        availableCards: cards
    )
}

private struct DashboardServiceMock: WallboxServiceProtocol {
    let result: Result<WallboxStatus, Error>

    func fetchStatus() async throws -> WallboxStatus {
        try result.get()
    }

    func updateChargingSettings(_: ChargingSettings) async throws {}
    func startCharging(cardIndex: Int) async throws {}
    func stopCharging() async throws {}
}

private final class StartChargingServiceMock: WallboxServiceProtocol {
    private(set) var lastStartedCardIndex: Int?
    private let status: WallboxStatus

    init(status: WallboxStatus) {
        self.status = status
    }

    func fetchStatus() async throws -> WallboxStatus {
        status
    }

    func updateChargingSettings(_: ChargingSettings) async throws {}

    func startCharging(cardIndex: Int) async throws {
        lastStartedCardIndex = cardIndex
    }

    func stopCharging() async throws {}
}

private final class ApplyChargeLimitServiceMock: WallboxServiceProtocol {
    private(set) var lastAppliedChargeLimitWh: Int?
    private(set) var updateCallCount = 0
    var updateError: Error?
    private var status: WallboxStatus

    init(
        initialStatus: WallboxStatus = WallboxStatus(
            isConnected: true,
            connectionState: .waiting,
            chargingPowerW: 0,
            energyPerDayWh: 0,
            chargeLimitWh: 0,
            forceState: 0,
            activeTransaction: -1,
            availableCards: []
        )
    ) {
        self.status = initialStatus
    }

    func fetchStatus() async throws -> WallboxStatus {
        status
    }

    func updateChargingSettings(_ chargingSettings: ChargingSettings) async throws {
        updateCallCount += 1
        if let updateError {
            throw updateError
        }
        let limit = chargingSettings.computedChargeLimitWh
        lastAppliedChargeLimitWh = limit
        status = WallboxStatus(
            isConnected: status.isConnected,
            connectionState: status.connectionState,
            chargingPowerW: status.chargingPowerW,
            energyPerDayWh: status.energyPerDayWh,
            chargeLimitWh: limit,
            forceState: status.forceState,
            activeTransaction: status.activeTransaction,
            availableCards: status.availableCards
        )
    }

    func startCharging(cardIndex: Int) async throws {}
    func stopCharging() async throws {}
}
