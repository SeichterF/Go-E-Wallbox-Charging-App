import Foundation
import Observation

@Observable
final class AppSettings {
    private enum StorageKeys {
        static let chargerIP = "chargerIP"
        static let batterySizeKWh = "batterySizeKWh"
        static let targetSOCPercent = "targetSOCPercent"
        static let chargingEnergyFactor = "chargingEnergyFactor"
        static let pollingIntervalSeconds = "pollingIntervalSeconds"
    }

    private enum DefaultValues {
        static let chargerIP = "192.168.178.69"
        static let batterySizeKWh = 42.0
        static let targetSOCPercent = 80
        static let chargingEnergyFactor = 0.85
        static let pollingIntervalSeconds: TimeInterval = 15.0
    }

    @ObservationIgnored private let defaults: UserDefaults

    var chargerIP: String {
        didSet { defaults.set(chargerIP, forKey: StorageKeys.chargerIP) }
    }
    var batterySizeKWh: Double {
        didSet { defaults.set(batterySizeKWh, forKey: StorageKeys.batterySizeKWh) }
    }
    var targetSOCPercent: Int {
        didSet { defaults.set(targetSOCPercent, forKey: StorageKeys.targetSOCPercent) }
    }
    var chargingEnergyFactor: Double {
        didSet { defaults.set(chargingEnergyFactor, forKey: StorageKeys.chargingEnergyFactor) }
    }
    var pollingIntervalSeconds: TimeInterval {
        didSet { defaults.set(pollingIntervalSeconds, forKey: StorageKeys.pollingIntervalSeconds) }
    }

    let minSOCPercent: Int = 10
    let maxSOCPercent: Int = 100
    let socStepPercent: Int = 5

    var apiBaseURLString: String {
        "http://\(chargerIP)/api/"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.chargerIP = defaults.string(forKey: StorageKeys.chargerIP)
            ?? DefaultValues.chargerIP
        self.batterySizeKWh = defaults.object(forKey: StorageKeys.batterySizeKWh) as? Double
            ?? DefaultValues.batterySizeKWh
        self.targetSOCPercent = defaults.object(forKey: StorageKeys.targetSOCPercent) as? Int
            ?? DefaultValues.targetSOCPercent
        self.chargingEnergyFactor = defaults.object(forKey: StorageKeys.chargingEnergyFactor) as? Double
            ?? DefaultValues.chargingEnergyFactor
        self.pollingIntervalSeconds = defaults.object(forKey: StorageKeys.pollingIntervalSeconds) as? TimeInterval
            ?? DefaultValues.pollingIntervalSeconds
    }
}
