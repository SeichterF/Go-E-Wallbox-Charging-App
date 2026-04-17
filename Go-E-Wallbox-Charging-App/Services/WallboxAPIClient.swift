import Foundation

struct WallboxAPIClient {
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    func fetchStatus() async throws -> WallboxStatus {
        guard URL(string: settings.apiBaseURLString) != nil else {
            throw URLError(.badURL)
        }

        // Placeholder implementation for architecture bootstrap.
        return WallboxStatus.placeholder
    }

    func updateChargingSettings(_ settings: ChargingSettings) async throws {
        guard URL(string: self.settings.apiBaseURLString) != nil else {
            throw URLError(.badURL)
        }

        _ = settings
        // Placeholder: real SET call will be added in feature implementation.
    }
}
