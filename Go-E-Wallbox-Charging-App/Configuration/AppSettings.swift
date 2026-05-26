import Foundation
import Observation

@Observable
final class AppSettings {
    var chargerIP: String = "192.168.178.69"
    var batterySizeKWh: Double = 42.0
    var targetSOCPercent: Int = 80
    var chargingEnergyFactor: Double = 0.85
    var pollingIntervalSeconds: TimeInterval = 15.0

    let minSOCPercent: Int = 10
    let maxSOCPercent: Int = 100
    let socStepPercent: Int = 5

    var apiBaseURLString: String {
        "http://\(chargerIP)/api/"
    }
}
