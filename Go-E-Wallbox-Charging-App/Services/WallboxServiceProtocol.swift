import Foundation

protocol WallboxServiceProtocol {
    func fetchStatus() async throws -> WallboxStatus
    func updateChargingSettings(_ settings: ChargingSettings) async throws
    func startCharging(cardIndex: Int, chargeLimitWh: Int) async throws
    func stopCharging() async throws
}
