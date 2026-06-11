import Foundation

struct WallboxStatus: Equatable {
    enum ConnectionState: Equatable {
        case disconnected
        case charging
        case waiting
        case complete
        case unknown
    }

    let isConnected: Bool
    let connectionState: ConnectionState
    let chargingPowerW: Int
    let energyPerDayWh: Int
    /// Active charge energy limit from wallbox `dwo` (Wh); `0` means no limit.
    let chargeLimitWh: Int

    var connectionStateLabel: String {
        switch connectionState {
        case .disconnected:
            return AppConstants.UI.statusDisconnected
        case .charging:
            return AppConstants.UI.statusCharging
        case .waiting:
            return AppConstants.UI.statusWaiting
        case .complete:
            return AppConstants.UI.statusComplete
        case .unknown:
            return AppConstants.UI.statusUnknown
        }
    }

    static let placeholder = WallboxStatus(
        isConnected: false,
        connectionState: .unknown,
        chargingPowerW: 0,
        energyPerDayWh: 0,
        chargeLimitWh: 0
    )
}
