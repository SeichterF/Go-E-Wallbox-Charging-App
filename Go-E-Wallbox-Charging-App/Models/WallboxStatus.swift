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
    /// go-e API `frc`: 0=neutral, 1=force off, 2=force on.
    let forceState: Int
    /// go-e API `trx`: active transaction card index (1-based); -1 means none.
    let activeTransaction: Int
    let availableCards: [RFIDCard]

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
        chargeLimitWh: 0,
        forceState: 0,
        activeTransaction: -1,
        availableCards: []
    )
}
