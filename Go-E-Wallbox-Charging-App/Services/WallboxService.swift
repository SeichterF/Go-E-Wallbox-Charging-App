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

    func updateChargingSettings(_ settings: ChargingSettings) async throws {
        try await apiClient.updateChargingSettings(settings)
    }
}
