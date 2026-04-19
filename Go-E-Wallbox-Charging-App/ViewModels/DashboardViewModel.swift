import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {
    private let service: WallboxServiceProtocol
    private let settings: AppSettings

    var isLoading = false
    var errorMessage: String?
    var status: WallboxStatus = .placeholder
    var currentSOCPercent: Int

    init(service: WallboxServiceProtocol, settings: AppSettings) {
        self.service = service
        self.settings = settings
        currentSOCPercent = settings.minSOCPercent
    }

    var targetSOCPercent: Int {
        settings.targetSOCPercent
    }

    var minSOCPercent: Int {
        settings.minSOCPercent
    }

    var maxSOCPercent: Int {
        settings.maxSOCPercent
    }

    var socStepPercent: Int {
        settings.socStepPercent
    }

    var chargingSettingsForApply: ChargingSettings {
        ChargingSettings(
            currentSOCPercent: currentSOCPercent,
            targetSOCPercent: settings.targetSOCPercent,
            batterySizeKWh: settings.batterySizeKWh,
            chargingEnergyDivisor: settings.chargingEnergyDivisor
        )
    }

    var previewChargeLimitWh: Int {
        chargingSettingsForApply.computedChargeLimitWh
    }

    func refreshStatus() async {
        isLoading = true
        errorMessage = nil

        do {
            status = try await service.fetchStatus()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func applyChargeLimit() async {
        isLoading = true
        errorMessage = nil

        let payload = chargingSettingsForApply

        do {
            try await service.updateChargingSettings(payload)
            status = try await service.fetchStatus()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
