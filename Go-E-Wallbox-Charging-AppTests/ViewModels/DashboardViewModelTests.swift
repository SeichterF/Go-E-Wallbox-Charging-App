import Testing
@testable import Go_E_Wallbox_Charging_App

struct DashboardViewModelTests {
    @MainActor
    @Test
    func refreshStatusUpdatesStatusOnSuccess() async {
        let service = DashboardServiceMock(result: .success(.init(isConnected: true, chargingPowerW: 11000, energyPerDayWh: 23000)))
        let viewModel = DashboardViewModel(service: service)

        await viewModel.refreshStatus()

        #expect(viewModel.status.isConnected)
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
