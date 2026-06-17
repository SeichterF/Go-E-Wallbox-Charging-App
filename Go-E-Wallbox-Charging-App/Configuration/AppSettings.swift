import Foundation
import Observation

protocol CloudKeyValueStore {
    func object(forKey key: String) -> Any?
    func set(_ value: Any?, forKey key: String)
    @discardableResult func synchronize() -> Bool
}

extension NSUbiquitousKeyValueStore: CloudKeyValueStore {}

@Observable
final class AppSettings {
    private enum StorageKeys {
        static let chargerIP = "chargerIP"
        static let batterySizeKWh = "batterySizeKWh"
        static let targetSOCPercent = "targetSOCPercent"
        static let chargingEnergyFactor = "chargingEnergyFactor"
        static let pollingIntervalSeconds = "pollingIntervalSeconds"
        static let selectedCardIndex = "selectedCardIndex"
    }

    private enum DefaultValues {
        static let chargerIP = "192.168.178.69"
        static let batterySizeKWh = 42.0
        static let targetSOCPercent = 80
        static let chargingEnergyFactor = 0.85
        static let pollingIntervalSeconds: TimeInterval = 15.0
        static let selectedCardIndex = 0
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let cloudStore: CloudKeyValueStore

    var chargerIP: String {
        didSet { persist(chargerIP, forKey: StorageKeys.chargerIP) }
    }
    var batterySizeKWh: Double {
        didSet { persist(batterySizeKWh, forKey: StorageKeys.batterySizeKWh) }
    }
    var targetSOCPercent: Int {
        didSet { persist(targetSOCPercent, forKey: StorageKeys.targetSOCPercent) }
    }
    var chargingEnergyFactor: Double {
        didSet { persist(chargingEnergyFactor, forKey: StorageKeys.chargingEnergyFactor) }
    }
    var pollingIntervalSeconds: TimeInterval {
        didSet { persist(pollingIntervalSeconds, forKey: StorageKeys.pollingIntervalSeconds) }
    }
    var selectedCardIndex: Int {
        didSet { persist(selectedCardIndex, forKey: StorageKeys.selectedCardIndex) }
    }
    /// Runtime cache of RFID cards fetched from the wallbox; not persisted across app restarts.
    var availableCards: [RFIDCard] = []

    let minSOCPercent: Int = 10
    let maxSOCPercent: Int = 100
    let socStepPercent: Int = 5

    var apiBaseURLString: String {
        "http://\(chargerIP)/api/"
    }

    init(
        defaults: UserDefaults = .standard,
        cloudStore: CloudKeyValueStore = NSUbiquitousKeyValueStore.default
    ) {
        self.defaults = defaults
        self.cloudStore = cloudStore
        cloudStore.synchronize()

        self.chargerIP = (cloudStore.object(forKey: StorageKeys.chargerIP) as? String)
            ?? defaults.string(forKey: StorageKeys.chargerIP)
            ?? DefaultValues.chargerIP
        self.batterySizeKWh = (cloudStore.object(forKey: StorageKeys.batterySizeKWh) as? Double)
            ?? (defaults.object(forKey: StorageKeys.batterySizeKWh) as? Double)
            ?? DefaultValues.batterySizeKWh
        self.targetSOCPercent = (cloudStore.object(forKey: StorageKeys.targetSOCPercent) as? Int)
            ?? (defaults.object(forKey: StorageKeys.targetSOCPercent) as? Int)
            ?? DefaultValues.targetSOCPercent
        self.chargingEnergyFactor = (cloudStore.object(forKey: StorageKeys.chargingEnergyFactor) as? Double)
            ?? (defaults.object(forKey: StorageKeys.chargingEnergyFactor) as? Double)
            ?? DefaultValues.chargingEnergyFactor
        self.pollingIntervalSeconds = (cloudStore.object(forKey: StorageKeys.pollingIntervalSeconds) as? TimeInterval)
            ?? (defaults.object(forKey: StorageKeys.pollingIntervalSeconds) as? TimeInterval)
            ?? DefaultValues.pollingIntervalSeconds
        self.selectedCardIndex = (cloudStore.object(forKey: StorageKeys.selectedCardIndex) as? Int)
            ?? (defaults.object(forKey: StorageKeys.selectedCardIndex) as? Int)
            ?? DefaultValues.selectedCardIndex
    }

    private func persist(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: key)
        cloudStore.set(value, forKey: key)
    }
}
