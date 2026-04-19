import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    private let settings: AppSettings

    var isLoading = false
    var errorMessage: String?

    var chargerIP: String
    var batterySizeKWh: Double
    var targetSOCPercent: Int
    var chargingEnergyDivisor: Double
    var minSOCPercent: Int
    var maxSOCPercent: Int
    var socStepPercent: Int

    init(settings: AppSettings) {
        self.settings = settings
        chargerIP = settings.chargerIP
        batterySizeKWh = settings.batterySizeKWh
        targetSOCPercent = settings.targetSOCPercent
        chargingEnergyDivisor = settings.chargingEnergyDivisor
        minSOCPercent = settings.minSOCPercent
        maxSOCPercent = settings.maxSOCPercent
        socStepPercent = settings.socStepPercent
    }

    func save() async {
        isLoading = true
        errorMessage = nil

        settings.chargerIP = chargerIP
        settings.batterySizeKWh = batterySizeKWh
        settings.targetSOCPercent = targetSOCPercent
        settings.chargingEnergyDivisor = chargingEnergyDivisor

        isLoading = false
    }
}
