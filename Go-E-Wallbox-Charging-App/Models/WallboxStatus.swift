import Foundation

struct WallboxStatus: Equatable {
    let isConnected: Bool
    let chargingPowerW: Int
    let energyPerDayWh: Int

    static let placeholder = WallboxStatus(
        isConnected: false,
        chargingPowerW: 0,
        energyPerDayWh: 0
    )
}
