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
        static let selectedCardIndex = -2 // -2 = auto (first card); -1 = explicit "no user"; >=0 = card id
    }

    private enum Limits {
        static let batterySizeKWh: ClosedRange<Double> = 1.0...250.0
        static let chargingEnergyFactor: ClosedRange<Double> = 0.5...1.0
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let cloudStore: CloudKeyValueStore

    var chargerIP: String {
        didSet { persist(chargerIP, forKey: StorageKeys.chargerIP) }
    }
    /// Always kept inside `batterySizeRange`; an out-of-range value would overflow
    /// `ChargingSettings.computedChargeLimitWh`. Assigning inside `didSet` does not re-enter it.
    var batterySizeKWh: Double {
        didSet {
            batterySizeKWh = Self.sanitize(
                batterySizeKWh,
                into: Limits.batterySizeKWh,
                fallback: DefaultValues.batterySizeKWh
            )
            persist(batterySizeKWh, forKey: StorageKeys.batterySizeKWh)
        }
    }
    var targetSOCPercent: Int {
        didSet { persist(targetSOCPercent, forKey: StorageKeys.targetSOCPercent) }
    }
    /// Always kept inside `chargingEnergyFactorRange`; see `batterySizeKWh` for why.
    var chargingEnergyFactor: Double {
        didSet {
            chargingEnergyFactor = Self.sanitize(
                chargingEnergyFactor,
                into: Limits.chargingEnergyFactor,
                fallback: DefaultValues.chargingEnergyFactor
            )
            persist(chargingEnergyFactor, forKey: StorageKeys.chargingEnergyFactor)
        }
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
    let batterySizeRange = Limits.batterySizeKWh
    let chargingEnergyFactorRange = Limits.chargingEnergyFactor

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
        // Sanitized on read as well as on write: a value stored by an earlier build (or synced
        // from iCloud) can be out of range, and would crash the Dashboard on every launch.
        let storedBatterySizeKWh = (cloudStore.object(forKey: StorageKeys.batterySizeKWh) as? Double)
            ?? (defaults.object(forKey: StorageKeys.batterySizeKWh) as? Double)
            ?? DefaultValues.batterySizeKWh
        self.batterySizeKWh = Self.sanitize(
            storedBatterySizeKWh,
            into: Limits.batterySizeKWh,
            fallback: DefaultValues.batterySizeKWh
        )
        self.targetSOCPercent = (cloudStore.object(forKey: StorageKeys.targetSOCPercent) as? Int)
            ?? (defaults.object(forKey: StorageKeys.targetSOCPercent) as? Int)
            ?? DefaultValues.targetSOCPercent
        let storedChargingEnergyFactor = (cloudStore.object(forKey: StorageKeys.chargingEnergyFactor) as? Double)
            ?? (defaults.object(forKey: StorageKeys.chargingEnergyFactor) as? Double)
            ?? DefaultValues.chargingEnergyFactor
        self.chargingEnergyFactor = Self.sanitize(
            storedChargingEnergyFactor,
            into: Limits.chargingEnergyFactor,
            fallback: DefaultValues.chargingEnergyFactor
        )
        self.pollingIntervalSeconds = (cloudStore.object(forKey: StorageKeys.pollingIntervalSeconds) as? TimeInterval)
            ?? (defaults.object(forKey: StorageKeys.pollingIntervalSeconds) as? TimeInterval)
            ?? DefaultValues.pollingIntervalSeconds
        self.selectedCardIndex = (cloudStore.object(forKey: StorageKeys.selectedCardIndex) as? Int)
            ?? (defaults.object(forKey: StorageKeys.selectedCardIndex) as? Int)
            ?? DefaultValues.selectedCardIndex

        // Write a repaired value straight back, otherwise the bad entry keeps sitting in
        // iCloud and would poison any other device that syncs it.
        if batterySizeKWh != storedBatterySizeKWh {
            persist(batterySizeKWh, forKey: StorageKeys.batterySizeKWh)
        }
        if chargingEnergyFactor != storedChargingEnergyFactor {
            persist(chargingEnergyFactor, forKey: StorageKeys.chargingEnergyFactor)
        }
    }

    /// NaN falls back to the default; everything else is clamped into `range`.
    private static func sanitize(
        _ value: Double,
        into range: ClosedRange<Double>,
        fallback: Double
    ) -> Double {
        guard !value.isNaN else { return fallback }
        return min(range.upperBound, max(range.lowerBound, value))
    }

    private func persist(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: key)
        cloudStore.set(value, forKey: key)
    }
}
