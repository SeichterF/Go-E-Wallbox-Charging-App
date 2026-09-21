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

    /// Starts charging by applying the energy limit, setting the active transaction to `cardIndex`
    /// (0-based) and releasing the force state to neutral.
    ///
    /// Neutral (`frc=0`) rather than force on (`frc=2`) is deliberate: force on sits above the
    /// energy-limit check in the wallbox's decision logic, so a forced session reports
    /// `modelStatus` 3 (ChargingBecauseForceStateOn) and never evaluates `dwo`. Neutral lets the
    /// default logic run (`modelStatus` 15) — the state the official go-e app's Basic mode
    /// produces — which is where the limit is honoured.
    ///
    /// Pass `cardIndex = -1` to start without assigning a user.
    func startCharging(cardIndex: Int, chargeLimitWh: Int) async throws {
        try await apiClient.setChargeEnergyLimitWh(chargeLimitWh)
        if cardIndex >= 0 {
            try await apiClient.setTransaction(cardIndex + 1)
        }
        try await apiClient.setForceState(0)
    }

    func stopCharging() async throws {
        try await apiClient.setForceState(1)
    }
}
