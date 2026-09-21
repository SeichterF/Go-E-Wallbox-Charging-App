import Foundation
import Testing
@testable import Go_E_Wallbox_Charging_App

final class MockCloudStore: CloudKeyValueStore {
    private var storage: [String: Any]
    private(set) var synchronizeCallCount = 0

    init(storage: [String: Any] = [:]) {
        self.storage = storage
    }

    func object(forKey key: String) -> Any? { storage[key] }
    func set(_ value: Any?, forKey key: String) { storage[key] = value }

    @discardableResult
    func synchronize() -> Bool {
        synchronizeCallCount += 1
        return true
    }
}

struct AppSettingsTests {
    private func makeCleanDefaults(suiteName: String) throws -> UserDefaults {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test
    func freshStoresYieldDefaultValues() throws {
        let defaults = try makeCleanDefaults(suiteName: "AppSettingsTests.fresh")
        let settings = AppSettings(defaults: defaults, cloudStore: MockCloudStore())

        #expect(settings.chargerIP == "192.168.178.69")
        #expect(settings.batterySizeKWh == 42.0)
        #expect(settings.targetSOCPercent == 80)
        #expect(settings.chargingEnergyFactor == 0.85)
        #expect(settings.pollingIntervalSeconds == 15.0)
    }

    @Test
    func changedValuesPersistAcrossInstances() throws {
        let defaults = try makeCleanDefaults(suiteName: "AppSettingsTests.persistence")
        let cloudStore = MockCloudStore()

        let settings = AppSettings(defaults: defaults, cloudStore: cloudStore)
        settings.chargerIP = "10.0.0.42"
        settings.batterySizeKWh = 60.0
        settings.targetSOCPercent = 90
        settings.chargingEnergyFactor = 0.9
        settings.pollingIntervalSeconds = 20.0

        let reloaded = AppSettings(defaults: defaults, cloudStore: cloudStore)

        #expect(reloaded.chargerIP == "10.0.0.42")
        #expect(reloaded.batterySizeKWh == 60.0)
        #expect(reloaded.targetSOCPercent == 90)
        #expect(reloaded.chargingEnergyFactor == 0.9)
        #expect(reloaded.pollingIntervalSeconds == 20.0)
    }

    @Test
    func unchangedValuesKeepDefaultsAfterPartialWrite() throws {
        let defaults = try makeCleanDefaults(suiteName: "AppSettingsTests.partial")
        let cloudStore = MockCloudStore()

        let settings = AppSettings(defaults: defaults, cloudStore: cloudStore)
        settings.chargerIP = "10.0.0.42"

        let reloaded = AppSettings(defaults: defaults, cloudStore: cloudStore)

        #expect(reloaded.chargerIP == "10.0.0.42")
        #expect(reloaded.batterySizeKWh == 42.0)
        #expect(reloaded.targetSOCPercent == 80)
    }

    @Test
    func cloudValuesSurviveReinstall() throws {
        // Simulates reinstall: UserDefaults wiped, iCloud still has the values.
        let defaults = try makeCleanDefaults(suiteName: "AppSettingsTests.reinstall")
        let cloudStore = MockCloudStore(storage: [
            "chargerIP": "10.0.0.42",
            "batterySizeKWh": 60.0,
            "targetSOCPercent": 90,
        ])

        let settings = AppSettings(defaults: defaults, cloudStore: cloudStore)

        #expect(settings.chargerIP == "10.0.0.42")
        #expect(settings.batterySizeKWh == 60.0)
        #expect(settings.targetSOCPercent == 90)
        #expect(settings.chargingEnergyFactor == 0.85)
        #expect(cloudStore.synchronizeCallCount == 1)
    }

    @Test
    func cloudValueTakesPrecedenceOverLocalDefaults() throws {
        let defaults = try makeCleanDefaults(suiteName: "AppSettingsTests.precedence")
        defaults.set("192.168.1.1", forKey: "chargerIP")
        let cloudStore = MockCloudStore(storage: ["chargerIP": "10.0.0.42"])

        let settings = AppSettings(defaults: defaults, cloudStore: cloudStore)

        #expect(settings.chargerIP == "10.0.0.42")
    }

    @Test
    func changesAreWrittenToBothStores() throws {
        let defaults = try makeCleanDefaults(suiteName: "AppSettingsTests.writeThrough")
        let cloudStore = MockCloudStore()

        let settings = AppSettings(defaults: defaults, cloudStore: cloudStore)
        settings.chargerIP = "10.0.0.42"

        #expect(defaults.string(forKey: "chargerIP") == "10.0.0.42")
        #expect(cloudStore.object(forKey: "chargerIP") as? String == "10.0.0.42")
    }

    // MARK: - Value sanitization (issue #41)

    @Test
    func outOfRangeStoredBatterySizeIsRepairedOnRead() throws {
        // Regression for #41: a poisoned value crashed the Dashboard on every launch,
        // and iCloud handed it back even after a reinstall.
        let defaults = try makeCleanDefaults(suiteName: "AppSettingsTests.poisonedBattery")
        let cloudStore = MockCloudStore(storage: ["batterySizeKWh": 1e30])

        let settings = AppSettings(defaults: defaults, cloudStore: cloudStore)

        #expect(settings.batterySizeKWh == 250.0)
        // The repaired value replaces the poisoned one, so no other device syncs it back.
        #expect(cloudStore.object(forKey: "batterySizeKWh") as? Double == 250.0)
        #expect(defaults.object(forKey: "batterySizeKWh") as? Double == 250.0)
    }

    @Test
    func notANumberStoredBatterySizeFallsBackToDefaultOnRead() throws {
        let defaults = try makeCleanDefaults(suiteName: "AppSettingsTests.nanBattery")
        let cloudStore = MockCloudStore(storage: ["batterySizeKWh": Double.nan])

        let settings = AppSettings(defaults: defaults, cloudStore: cloudStore)

        #expect(settings.batterySizeKWh == 42.0)
    }

    @Test
    func outOfRangeStoredChargingFactorIsRepairedOnRead() throws {
        let defaults = try makeCleanDefaults(suiteName: "AppSettingsTests.poisonedFactor")
        let cloudStore = MockCloudStore(storage: ["chargingEnergyFactor": 0.0001])

        let settings = AppSettings(defaults: defaults, cloudStore: cloudStore)

        #expect(settings.chargingEnergyFactor == 0.5)
    }

    @Test
    func outOfRangeWrittenValuesAreClampedAndPersistedClamped() throws {
        let defaults = try makeCleanDefaults(suiteName: "AppSettingsTests.clampOnWrite")
        let cloudStore = MockCloudStore()

        let settings = AppSettings(defaults: defaults, cloudStore: cloudStore)
        settings.batterySizeKWh = 1_000.0
        settings.chargingEnergyFactor = 2.0

        #expect(settings.batterySizeKWh == 250.0)
        #expect(settings.chargingEnergyFactor == 1.0)
        #expect(defaults.object(forKey: "batterySizeKWh") as? Double == 250.0)
        #expect(cloudStore.object(forKey: "chargingEnergyFactor") as? Double == 1.0)
    }

    @Test
    func valuesInsideTheAllowedRangeAreUntouched() throws {
        let defaults = try makeCleanDefaults(suiteName: "AppSettingsTests.inRange")

        let settings = AppSettings(defaults: defaults, cloudStore: MockCloudStore())
        settings.batterySizeKWh = 77.5
        settings.chargingEnergyFactor = 0.92

        #expect(settings.batterySizeKWh == 77.5)
        #expect(settings.chargingEnergyFactor == 0.92)
    }
}
