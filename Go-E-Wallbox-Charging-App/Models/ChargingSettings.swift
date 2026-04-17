import Foundation

struct ChargingSettings: Equatable {
    let targetSOCPercent: Int
    let batterySizeKWh: Double
    let chargingLossFactor: Double
}
