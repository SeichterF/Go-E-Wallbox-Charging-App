import Foundation
import Testing
@testable import Go_E_Wallbox_Charging_App

@MainActor
struct SettingsViewModelTests {
    private func makeSettings(suiteName: String) throws -> AppSettings {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return AppSettings(defaults: defaults, cloudStore: MockCloudStore())
    }

    @Test
    func validBatterySizeIsWrittenThroughToSettings() throws {
        let settings = try makeSettings(suiteName: "SettingsViewModelTests.validBattery")
        let viewModel = SettingsViewModel(settings: settings)

        viewModel.replaceBatterySizeTextWithSanitizedUserInput("60")

        #expect(viewModel.batterySizeValidationError == nil)
        #expect(settings.batterySizeKWh == 60.0)
    }

    @Test
    func outOfRangeBatterySizeIsReportedAndNeverReachesSettings() throws {
        // The input that caused the crash in #41.
        let settings = try makeSettings(suiteName: "SettingsViewModelTests.invalidBattery")
        let viewModel = SettingsViewModel(settings: settings)

        viewModel.replaceBatterySizeTextWithSanitizedUserInput("999999999999")

        #expect(viewModel.batterySizeValidationError != nil)
        #expect(settings.batterySizeKWh == 42.0)
    }

    @Test
    func endEditingRestoresTheTextOfThePersistedValue() throws {
        let settings = try makeSettings(suiteName: "SettingsViewModelTests.endEditing")
        let viewModel = SettingsViewModel(settings: settings)

        viewModel.replaceBatterySizeTextWithSanitizedUserInput("999999999999")
        viewModel.endEditingBatterySize()

        #expect(viewModel.batterySizeText == "42")
        #expect(viewModel.batterySizeValidationError == nil)
    }

    @Test
    func nonNumericCharactersAreStrippedFromInput() throws {
        let settings = try makeSettings(suiteName: "SettingsViewModelTests.sanitize")
        let viewModel = SettingsViewModel(settings: settings)

        viewModel.replaceBatterySizeTextWithSanitizedUserInput("6e0a.5.7")

        #expect(viewModel.batterySizeText == "60.57")
        #expect(settings.batterySizeKWh == 60.57)
    }

    @Test
    func commaIsAcceptedAsDecimalSeparator() throws {
        let settings = try makeSettings(suiteName: "SettingsViewModelTests.comma")
        let viewModel = SettingsViewModel(settings: settings)

        viewModel.replaceChargingEnergyFactorTextWithSanitizedUserInput("0,9")

        #expect(viewModel.chargingEnergyFactorValidationError == nil)
        #expect(settings.chargingEnergyFactor == 0.9)
    }

    @Test
    func outOfRangeChargingFactorIsReportedAndNeverReachesSettings() throws {
        let settings = try makeSettings(suiteName: "SettingsViewModelTests.invalidFactor")
        let viewModel = SettingsViewModel(settings: settings)

        viewModel.replaceChargingEnergyFactorTextWithSanitizedUserInput("0.0001")

        #expect(viewModel.chargingEnergyFactorValidationError != nil)
        #expect(settings.chargingEnergyFactor == 0.85)
    }

    @Test
    func partialInputIsNotReportedAsInvalid() throws {
        let settings = try makeSettings(suiteName: "SettingsViewModelTests.partial")
        let viewModel = SettingsViewModel(settings: settings)

        viewModel.replaceBatterySizeTextWithSanitizedUserInput("")

        #expect(viewModel.batterySizeValidationError == nil)
        #expect(settings.batterySizeKWh == 42.0)
    }
}
