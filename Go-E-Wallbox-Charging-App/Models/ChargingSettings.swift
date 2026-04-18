import Foundation

struct ChargingSettings: Equatable {
    let currentSOCPercent: Int
    let targetSOCPercent: Int
    let batterySizeKWh: Double
    let chargingLossFactor: Double

    /// Charge energy limit in Wh for go-e `dwo`, following CONTEXT.md (Shortcut parity).
    var computedChargeLimitWh: Int {
        let deltaSOC = targetSOCPercent - currentSOCPercent
        guard deltaSOC > 0 else {
            return 0
        }

        let netEnergy = Double(deltaSOC) / 100.0 * batterySizeKWh
        let grossEnergy = netEnergy * chargingLossFactor
        return Int((grossEnergy * 1000.0).rounded())
    }
}
