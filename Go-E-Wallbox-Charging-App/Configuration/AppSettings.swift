import Foundation
import Observation

/// Abstraction over `NSUbiquitousKeyValueStore` so tests can inject an in-memory store.
protocol CloudKeyValueStore {
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
    @discardableResult
    func synchronize() -> Bool
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
    }

    private enum DefaultValues {
        static let chargerIP = "192.168.178.69"
        static let batterySizeKWh = 42.0
        static let targetSOCPercent = 80
        static let chargingEnergyFactor = 0.85
        static let pollingIntervalSeconds: TimeInterval = 15.0
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

        self.chargerIP = Self.storedValue(forKey: StorageKeys.chargerIP, cloudStore: cloudStore, defaults: defaults)
            ?? DefaultValues.chargerIP
        self.batterySizeKWh = Self.storedValue(forKey: StorageKeys.batterySizeKWh, cloudStore: cloudStore, defaults: defaults)
            ?? DefaultValues.batterySizeKWh
        self.targetSOCPercent = Self.storedValue(forKey: StorageKeys.targetSOCPercent, cloudStore: cloudStore, defaults: defaults)
            ?? DefaultValues.targetSOCPercent
        self.chargingEnergyFactor = Self.storedValue(forKey: StorageKeys.chargingEnergyFactor, cloudStore: cloudStore, defaults: defaults)
            ?? DefaultValues.chargingEnergyFactor
        self.pollingIntervalSeconds = Self.storedValue(forKey: StorageKeys.pollingIntervalSeconds, cloudStore: cloudStore, defaults: defaults)
            ?? DefaultValues.pollingIntervalSeconds
    }

    /// Reads a stored value preferring iCloud over local defaults, so settings
    /// survive reinstalls and follow the user's Apple ID across devices.
    private static func storedValue<Value>(
        forKey key: String,
        cloudStore: CloudKeyValueStore,
        defaults: UserDefaults
    ) -> Value? {
        if let cloudValue = cloudStore.object(forKey: key) as? Value {
            return cloudValue
        }
        return defaults.object(forKey: key) as? Value
    }

    private func persist(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: key)
        cloudStore.set(value, forKey: key)
    }
}
