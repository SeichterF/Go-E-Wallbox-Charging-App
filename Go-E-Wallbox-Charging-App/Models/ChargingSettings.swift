import Foundation

struct ChargingSettings: Equatable {
    let currentSOCPercent: Int
    let targetSOCPercent: Int
    let batterySizeKWh: Double
    let chargingLossFactor: Double

    /// Charge energy limit in Wh for go-e `dwo`: energy still needed in the battery until target SOC, converted to Wh, divided by the settings factor (e.g. 0.85).
    var computedChargeLimitWh: Int {
        let deltaSOC = targetSOCPercent - currentSOCPercent
        guard deltaSOC > 0, chargingLossFactor > 0 else {
            return 0
        }

        let neededBatteryKWh = Double(deltaSOC) / 100.0 * batterySizeKWh
        let neededBatteryWh = neededBatteryKWh * 1000.0
        let wallboxWh = neededBatteryWh / chargingLossFactor
        return Int(wallboxWh.rounded())
    }
}
