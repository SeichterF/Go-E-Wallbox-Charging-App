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

    /// Starts charging by setting the active transaction to `cardIndex` (0-based) and forcing on.
    /// Pass `cardIndex = -1` to start without assigning a user.
    func startCharging(cardIndex: Int) async throws {
        if cardIndex >= 0 {
            try await apiClient.setTransaction(cardIndex + 1)
        }
        try await apiClient.setForceState(2)
    }

    func stopCharging() async throws {
        try await apiClient.setForceState(1)
    }
}
