import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    private let settings: AppSettings

    var isLoading = false
    var errorMessage: String?

    var chargerIP: String {
        get { settings.chargerIP }
        set { settings.chargerIP = newValue }
    }

    /// Draft text for the battery size; only written through to `AppSettings` while in range.
    var batterySizeText: String
    /// Draft text for the charging energy factor; only written through to `AppSettings` while in range.
    var chargingEnergyFactorText: String

    init(settings: AppSettings) {
        self.settings = settings
        self.batterySizeText = Self.text(for: settings.batterySizeKWh)
        self.chargingEnergyFactorText = Self.text(for: settings.chargingEnergyFactor)
    }

    var batterySizeValidationError: String? {
        validationError(
            for: batterySizeText,
            range: settings.batterySizeRange,
            format: AppConstants.UI.batterySizeValidationErrorRange
        )
    }

    var chargingEnergyFactorValidationError: String? {
        validationError(
            for: chargingEnergyFactorText,
            range: settings.chargingEnergyFactorRange,
            format: AppConstants.UI.chargingFactorValidationErrorRange
        )
    }

    /// Strips everything but digits and a single decimal separator; persists only a valid value.
    func replaceBatterySizeTextWithSanitizedUserInput(_ raw: String) {
        batterySizeText = Self.sanitizeDecimalInput(raw)
        guard let value = Self.parse(batterySizeText),
              settings.batterySizeRange.contains(value) else { return }
        settings.batterySizeKWh = value
    }

    /// See `replaceBatterySizeTextWithSanitizedUserInput(_:)`.
    func replaceChargingEnergyFactorTextWithSanitizedUserInput(_ raw: String) {
        chargingEnergyFactorText = Self.sanitizeDecimalInput(raw)
        guard let value = Self.parse(chargingEnergyFactorText),
              settings.chargingEnergyFactorRange.contains(value) else { return }
        settings.chargingEnergyFactor = value
    }

    /// Discards an invalid draft so the field never keeps a value the settings do not hold.
    func endEditingBatterySize() {
        batterySizeText = Self.text(for: settings.batterySizeKWh)
    }

    /// See `endEditingBatterySize()`.
    func endEditingChargingEnergyFactor() {
        chargingEnergyFactorText = Self.text(for: settings.chargingEnergyFactor)
    }

    private func validationError(
        for text: String,
        range: ClosedRange<Double>,
        format: String
    ) -> String? {
        guard let value = Self.parse(text), !range.contains(value) else { return nil }
        return String(format: format, range.lowerBound, range.upperBound)
    }

    private static func text(for value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
    }

    private static func parse(_ text: String) -> Double? {
        guard !text.isEmpty else { return nil }
        return Double(text.replacingOccurrences(of: ",", with: "."))
    }

    private static func sanitizeDecimalInput(_ raw: String) -> String {
        var sanitized = ""
        var hasSeparator = false

        for character in raw {
            if character.isNumber {
                sanitized.append(character)
            } else if character == "." || character == "," {
                guard !hasSeparator else { continue }
                hasSeparator = true
                sanitized.append(character)
            }
        }

        return sanitized
    }
}
