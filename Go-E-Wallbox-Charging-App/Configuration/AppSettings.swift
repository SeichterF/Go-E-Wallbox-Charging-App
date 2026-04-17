import Foundation
import Observation

@Observable
final class AppSettings {
    var chargerIP: String = "192.168.1.100"
    var batterySizeKWh: Double = 60.0
    var targetSOCPercent: Int = 80
    var chargingLossFactor: Double = 1.10
    var pollingIntervalSeconds: TimeInterval = 15.0

    let minSOCPercent: Int = 10
    let maxSOCPercent: Int = 100
    let socStepPercent: Int = 5

    var apiBaseURLString: String {
        "http://\(chargerIP)/api/"
    }
}
