import Foundation

struct ChargingSettings: Equatable {
    let currentSOCPercent: Int
    let targetSOCPercent: Int
    let batterySizeKWh: Double
    let chargingEnergyFactor: Double

    /// Charge energy limit in Wh for go-e `dwo`: energy still needed in the battery until target SOC, converted to Wh, divided by `chargingEnergyFactor` (e.g. 0.85) to account for charging losses between wallbox and battery.
    var computedChargeLimitWh: Int {
        let deltaSOC = targetSOCPercent - currentSOCPercent
        guard deltaSOC > 0, chargingEnergyFactor > 0 else {
            return 0
        }

        let neededBatteryKWh = Double(deltaSOC) / 100.0 * batterySizeKWh
        let neededBatteryWh = neededBatteryKWh * 1000.0
        let wallboxWh = neededBatteryWh / chargingEnergyFactor
        return Int(wallboxWh.rounded())
    }
}
