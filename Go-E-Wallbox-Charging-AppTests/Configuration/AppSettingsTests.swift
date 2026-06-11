import Foundation
import Testing
@testable import Go_E_Wallbox_Charging_App

struct AppSettingsTests {
    private func makeCleanDefaults(suiteName: String) throws -> UserDefaults {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test
    func freshDefaultsYieldDefaultValues() throws {
        let suiteName = "AppSettingsTests.fresh"
        let defaults = try makeCleanDefaults(suiteName: suiteName)

        let settings = AppSettings(defaults: defaults)

        #expect(settings.chargerIP == "192.168.178.69")
        #expect(settings.batterySizeKWh == 42.0)
        #expect(settings.targetSOCPercent == 80)
        #expect(settings.chargingEnergyFactor == 0.85)
        #expect(settings.pollingIntervalSeconds == 15.0)
    }

    @Test
    func changedValuesPersistAcrossInstances() throws {
        let suiteName = "AppSettingsTests.persistence"
        let defaults = try makeCleanDefaults(suiteName: suiteName)

        let settings = AppSettings(defaults: defaults)
        settings.chargerIP = "10.0.0.42"
        settings.batterySizeKWh = 60.0
        settings.targetSOCPercent = 90
        settings.chargingEnergyFactor = 0.9
        settings.pollingIntervalSeconds = 20.0

        let reloaded = AppSettings(defaults: defaults)

        #expect(reloaded.chargerIP == "10.0.0.42")
        #expect(reloaded.batterySizeKWh == 60.0)
        #expect(reloaded.targetSOCPercent == 90)
        #expect(reloaded.chargingEnergyFactor == 0.9)
        #expect(reloaded.pollingIntervalSeconds == 20.0)
    }

    @Test
    func unchangedValuesKeepDefaultsAfterPartialWrite() throws {
        let suiteName = "AppSettingsTests.partial"
        let defaults = try makeCleanDefaults(suiteName: suiteName)

        let settings = AppSettings(defaults: defaults)
        settings.chargerIP = "10.0.0.42"

        let reloaded = AppSettings(defaults: defaults)

        #expect(reloaded.chargerIP == "10.0.0.42")
        #expect(reloaded.batterySizeKWh == 42.0)
        #expect(reloaded.targetSOCPercent == 80)
    }
}
