import Foundation

struct WallboxService: WallboxServiceProtocol {
    private let apiClient: WallboxAPIClient
    private let settings: AppSettings

    init(apiClient: WallboxAPIClient, settings: AppSettings) {
        self.apiClient = apiClient
        self.settings = settings
    }

    func fetchStatus() async throws -> WallboxStatus {
        _ = settings.pollingIntervalSeconds
        return try await apiClient.fetchStatus()
    }

    func updateChargingSettings(_ chargingSettings: ChargingSettings) async throws {
        let dwoWh = chargingSettings.computedChargeLimitWh
        try await apiClient.setChargeEnergyLimitWh(dwoWh)
    }
}
