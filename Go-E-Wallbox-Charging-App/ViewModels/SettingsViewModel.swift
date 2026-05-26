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
    var batterySizeKWh: Double {
        get { settings.batterySizeKWh }
        set { settings.batterySizeKWh = newValue }
    }
    var targetSOCPercent: Int {
        get { settings.targetSOCPercent }
        set { settings.targetSOCPercent = newValue }
    }
    var chargingEnergyFactor: Double {
        get { settings.chargingEnergyFactor }
        set { settings.chargingEnergyFactor = newValue }
    }
    var minSOCPercent: Int { settings.minSOCPercent }
    var maxSOCPercent: Int { settings.maxSOCPercent }
    var socStepPercent: Int { settings.socStepPercent }

    init(settings: AppSettings) {
        self.settings = settings
    }
}
